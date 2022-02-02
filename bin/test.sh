#!/bin/bash
set -e
eval "$(.lua/bin/luarocks path)"
.lua/bin/luacheck wowcig.lua
