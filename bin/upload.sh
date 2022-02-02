#!/bin/bash
v=${1:1}
key=${2}
spec=wowcig-${v}-0.rockspec
eval "$(.lua/bin/luarocks path)"
.lua/bin/luarocks install dkjson
sed s/scm/"${v}"/g < wowcig-scm-0.rockspec > "${spec}"
.lua/bin/luarocks upload --skip-pack --force --temp-key "${key}" "${spec}"
