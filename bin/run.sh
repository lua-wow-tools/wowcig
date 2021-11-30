#!/bin/bash
set -e
eval $(.lua/bin/luarocks path)
.lua/bin/luacheck wowcig.lua
.lua/bin/luarocks build --no-install
.lua/bin/lua wowcig.lua "$@"
