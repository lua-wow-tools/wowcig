local args = (function()
  local parser = require('argparse')()
  parser:option('-c --cache', 'cache directory', 'cache')
  parser:option('-d --db2', 'db2 to extract'):count('*')
  parser:option('-e --extracts', 'extracts directory', 'extracts')
  parser:option('-l --local', 'Use local WoW Directory instead of CDN.')
  parser:option('-p --product', 'WoW product'):count(1):choices({
    'wow',
    'wowt',
    'wow_classic',
    'wow_classic_era',
    'wow_classic_era_ptr',
    'wow_classic_ptr',
  })
  parser:flag('-r --resolvetocdn', 'wowcig will use the CDN for data not available locally.')
  parser:flag('-v --verbose', 'verbose printing')
  parser:flag('-x --skip-framexml', 'skip framexml extraction')
  parser:flag('-z --zip', 'write zip files instead of directory trees')
  return parser:parse()
end)()

local dbds = require('luadbd').dbds
local path = require('path')

local function normalizePath(p)
  -- path.normalize does not normalize x/../y to y.
  -- Unfortunately, we need exactly that behavior for Interface_Vanilla etc.
  -- links in per-product TOCs. We hack around it here by adding an extra dir.
  return path.normalize('a/' .. p):sub(3)
end

path.mkdir(args.cache)

local function log(...)
  if args.verbose then
    print(...)
  end
end

local encryptionKeys = (function()
  local url = 'https://raw.githubusercontent.com/wowdev/TACTKeys/master/WoW.txt'
  local wowtxt = require('ssl.https').request(url)
  local ret = {}
  for line in wowtxt:gmatch('[^\r\n]+') do
    local k, v = line:match('^([0-9A-F]+) ([0-9A-F]+)')
    ret[k:lower()] = v:lower()
  end
  return ret
end)()

local load, save, onexit, version = (function()
  local casc = require('casc')
  local handle, err, bkey, cdn, ckey, version
  if args['local'] then
    local bldInfoFile = path.join(args['local'], '.build.info')
    local _, buildInfo = casc.localbuild(bldInfoFile)

    for _, build in pairs(buildInfo) do
      if build.Product == args.product then
        version = build.Version
        break
      end
    end
    if not version then
      if not args.resolvetocdn then
        print('No local data for ' .. args.product .. ' in ' .. args['local'])
        os.exit()
      end
      log('No local data for ' .. args.product .. ' in ' .. args['local'] .. '. Will attempt to use CDN.')
    else
      log('loading', version, args.product, args['local'])
      local localConf = casc.conf(args['local'])
      localConf.keys = encryptionKeys
      handle, err = casc.open(localConf)
    end
  end
  if not handle then
    local url = 'http://us.patch.battle.net:1119/' .. args.product
    bkey, cdn, ckey, version = casc.cdnbuild(url, 'us')
    assert(bkey)
    log('loading', version, url)
    handle, err = casc.open({
      bkey = bkey,
      cdn = cdn,
      ckey = ckey,
      cache = args.cache,
      cacheFiles = true,
      keys = encryptionKeys,
      locale = casc.locale.US,
      log = log,
      zerofillEncryptedChunks = true,
    })
  end
  if not handle then
    print('unable to open ' .. args.product .. ': ' .. err)
    os.exit()
  end
  local zipfile
  if args.zip then
    local z = require('brimworks.zip')
    local filename = path.join(args.extracts, version .. '.zip')
    path.remove(filename)
    zipfile = assert(z.open(filename, z.OR(z.CREATE, z.EXCL)))
  end
  local fdids = {}
  do
    local dbd = dbds.manifestinterfacedata
    local filedb = assert(handle:readFile(dbd.fdid))
    local build = assert(dbd:build(version))
    for row in build:rows(filedb) do
      fdids[normalizePath(row.FilePath .. row.FileName)] = row.ID
    end
  end
  local function load(f)
    return handle:readFile(fdids[f] or f)
  end
  local function save(f, c)
    if not c then
      log('skipping', f)
    else
      log('writing ', f)
      if zipfile then
        local t = {}
        if type(c) == 'function' then
          c(function(s)
            table.insert(t, s)
          end)
        else
          table.insert(t, c)
        end
        local content = table.concat(t, '')
        local fn = path.join(version, f)
        local idx = zipfile:name_locate(fn)
        if idx then
          zipfile:replace(idx, 'string', content)
        else
          zipfile:add(fn, 'string', content)
        end
      else
        local fn = path.join(args.extracts, version, f)
        path.mkdir(path.dirname(fn))
        local fd = assert(io.open(fn, 'w'))
        if type(c) == 'function' then
          c(function(s)
            fd:write(s)
          end)
        else
          fd:write(c)
        end
        fd:close()
      end
    end
  end
  local function onexit()
    if zipfile then
      zipfile:close()
      require('pl.file').write(path.join(args.extracts, args.product .. '.txt'), version .. '\n')
    else
      require('lfs').link(version, path.join(args.extracts, args.product), true)
    end
  end
  return load, save, onexit, version
end)()

local function joinRelative(relativeTo, suffix)
  return normalizePath(path.join(path.dirname(relativeTo), suffix))
end

local processFile = (function()
  local lxp = require('lxp')
  local function doProcessFile(fn)
    local content = load(fn)
    save(fn, content)
    if fn:sub(-4) == '.xml' then
      local parser = lxp.new({
        StartElement = function(_, name, attrs)
          local lname = string.lower(name)
          if (lname == 'include' or lname == 'script') and attrs.file then
            doProcessFile(joinRelative(fn, attrs.file))
          end
        end,
      })
      parser:parse(content)
      parser:close()
    end
  end
  return doProcessFile
end)()

local function processToc(tocName)
  local toc = load(tocName)
  save(tocName, toc)
  if toc then
    for line in toc:gmatch('[^\r\n]+') do
      if line:sub(1, 1) ~= '#' then
        processFile(joinRelative(tocName, line:gsub('%s*$', '')))
      end
    end
  end
end

local productSuffixes = {
  '',
  '_Vanilla',
  '_TBC',
  '_Mainline',
}

if not args.skip_framexml then
  local function processAllProductFiles(addonDir)
    assert(addonDir:sub(1, 10) == 'Interface/', addonDir)
    local addonName = path.basename(addonDir)
    for _, suffix in ipairs(productSuffixes) do
      processToc(path.join(addonDir, addonName .. suffix .. '.toc'))
      processFile(path.join('Interface' .. suffix, addonDir:sub(11), 'Bindings.xml'))
    end
  end
  processAllProductFiles('Interface/FrameXML')
  do
    local dbd = dbds.manifestinterfacetocdata
    local tocdb = assert(load(dbd.fdid))
    local build = assert(dbd:build(version))
    for dir in build:rows(tocdb) do
      processAllProductFiles(normalizePath(dir.FilePath))
    end
  end
end

local alldb2s = false
for _, db2 in ipairs(args.db2) do
  alldb2s = alldb2s or string.lower(db2) == 'all'
end
if alldb2s then
  for name, dbd in pairs(dbds) do
    if dbd:build(version) then
      save(('db2/%s.db2'):format(name), function(write)
        write(assert(load(dbd.fdid)))
      end)
    end
  end
else
  for _, db2 in ipairs(args.db2) do
    local name = string.lower(db2)
    save(('db2/%s.db2'):format(name), function(write)
      write(assert(load(assert(dbds[name]).fdid)))
    end)
  end
end

onexit()
