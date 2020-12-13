# lua-gitweb

A git web client for Lua, similar to stagit.

## Requirements

Lua modules (Lua 5.1/LuaJIT 2.1.0/OpenResty LuaJIT compatible, accessible from Lua path/cpath):

| Module | Description |
| ------ | ----------- |
| [lfs](https://github.com/keplerproject/luafilesystem) | Filesystem API |
| [lyaml](https://github.com/gvvaughan/lyaml) | Reads and parses YAML config files |
| [puremagic](https://github.com/wbond/puremagic) | MIME type by content, used in blob rendering |

Other command line tools (installed on system path, accessible from shell):

| Program | Description |
| ------- | ----------- |
| [md4c](https://github.com/mity/md4c) (md2html) | Renders GitHub flavored Markdown |
| [highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php) | Syntax highlighting in HTML format |

Linkable Libraries (installed on system path, accessible with LuaJIT's C FFI):

| Library | Description |
| ------- | ----------- |
| [libgit2](https://github.com/libgit2/libgit2) | Linkable C API for Git |

## Copyright and Licensing

This package is copyrighted by [Joshua 'joshuas3'
Stockin](https://joshstock.in/) and licensed under the [MIT License](LICENSE).

&lt;<https://joshstock.in>&gt; | josh@joshstock.in | joshuas3#9641
