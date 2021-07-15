# wowcig
A WoW client interface getter.

```sh
luarocks install wowcig
wowcig -p wow_classic
```

The above will fetch the Lua/XML development files for WoW Classic and place them in the `extracts/` subdirectory.

`wowcig` is just a very simple wrapper around [luacasc] and [luadbc], two foundational bits of technology from townlong-yak.com.

[luacasc]: https://www.townlong-yak.com/casc/
[luadbc]: https://www.townlong-yak.com/casc/dbc/
