local path = require('path')

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

local tap = (function()
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
    locale = casc.locale.US,
    log = print,
  })
  return function(f)
    print('fetching', f)
    local content = handle:readFile(f)
    local fn = path.join(args.extracts, version, f)
    print('writing', fn)
    path.mkdir(path.dirname(fn))
    local fd = assert(io.open(fn, 'w'))
    fd:write(content)
    fd:close()
    return content
  end
end)()

do
  local tocName = 'Interface/FrameXML/FrameXML.toc'
  local toc = tap(tocName)
  for line in toc:gmatch('[^\r\n]+') do
    if line:sub(1, 1) ~= '#' then
      tap(path.normalize(path.join(path.dirname(tocName), line)))
    end
  end
end
