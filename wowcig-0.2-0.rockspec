rockspec_format = '3.0'
package = 'wowcig'
version = '0.2-0'
description = {
  summary = 'WoW client interface generator',
  license = 'MIT',
  homepage = 'https://github.com/ferronn-dev/wowcig',
  issues_url = 'https://github.com/ferronn-dev/wowcig/issues',
  maintainer = 'ferronn@ferronn.dev',
  labels = {'wow'},
}
source = {
  url = 'git://github.com/ferronn-dev/wowcig',
}
dependencies = {
  'lua = 5.1',
  'argparse',
  'lua-path',
  'luabitop',
  'luacasc',
  'luadbc',
  'luaexpat',
  'luafilesystem',
  'luasocket',
  'lzlib',
  'md5',
}
build = {
  type = 'none',
  install = {
    bin = {
      wowcig = 'wowcig.lua',
    },
  },
}
