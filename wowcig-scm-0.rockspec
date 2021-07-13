rockspec_format = '3.0'
package = 'wowcig'
version = 'scm-0'
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
  'luafilesystem',
  'luasocket',
  'lzlib',
  'md5',
}
build = {
  type = 'none',
  install = {
    lua = {
      wowcig = 'wowcig.lua',
    },
  },
}
