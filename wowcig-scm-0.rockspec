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
  'luacasc',
  'luafilesystem',
}
build = {
  type = 'none',
  install = {
    lua = {
      wowcig = 'wowcig.lua',
    },
  },
}
