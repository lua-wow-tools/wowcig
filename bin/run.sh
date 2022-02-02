#!/bin/bash
set -e
eval "$(.lua/bin/luarocks path)"
.lua/bin/luarocks build --no-install
.lua/bin/lua wowcig.lua "$@"
