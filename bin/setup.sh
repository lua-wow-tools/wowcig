#!/bin/bash
set -e
python3 -m pip install -t .lua git+https://github.com/luarocks/hererocks
PYTHONPATH=.lua .lua/bin/hererocks -l 5.1 -r 3.8.0 .lua
eval "$(.lua/bin/luarocks path)"
.lua/bin/luarocks install luacheck
.lua/bin/luarocks build --only-deps
