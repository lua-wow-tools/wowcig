local args = (function()
  local parser = require('argparse')()
  parser:option('-c --cache', 'cache directory', 'cache')
  parser:option('-e --extracts', 'extracts directory', 'extracts')
  parser:option('-p --product', 'WoW product'):choices({
    'wow',
    'wow_classic',
    'wow_classic_era',
  })
  return parser:parse()
end)()

local path = require('path')

path.mkdir(args.cache)

local load, save = (function()
  local casc = require('casc')
  local url = 'http://us.patch.battle.net:1119/' .. args.product
  local bkey, cdn, ckey, version = casc.cdnbuild(url, 'us')
  assert(bkey)
  print('loading', version)
  local handle = casc.open({
    bkey = bkey,
    cdn = cdn,
    ckey = ckey,
    cache = args.cache,
    cacheFiles = true,
    locale = casc.locale.US,
    log = print,
  })
  local function load(f)
    return handle:readFile(f)
  end
  local function save(f, c)
    print('writing ', f)
    local fn = path.join(args.extracts, version, f)
    path.mkdir(path.dirname(fn))
    local fd = assert(io.open(fn, 'w'))
    fd:write(c)
    fd:close()
  end
  return load, save
end)()

do
  local tocName = 'Interface/FrameXML/FrameXML.toc'
  local toc = load(tocName)
  save(tocName, toc)
  for line in toc:gmatch('[^\r\n]+') do
    if line:sub(1, 1) ~= '#' then
      local fn = path.normalize(path.join(path.dirname(tocName), line))
      local content = load(fn)
      save(fn, content)
    end
  end
end
