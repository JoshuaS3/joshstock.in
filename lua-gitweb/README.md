# lua-gitweb

A git web client for Lua, similar to stagit.

## Requirements

Required Lua modules (Lua 5.1/LuaJIT 2.1.0/OpenResty LuaJIT)
```
lyaml      Reads and parses YAML config files  https://github.com/gvvaughan/lyaml
puremagic  Identifies MIME type by content     https://github.com/wbond/puremagic
```

Other command line tools (must be installed on system path, accessible from
shell)
```
git        Frontend for libgit2, offers shell access     https://git-scm.com/
md4c       Renders GitHub flavored Markdown              https://github.com/mity/md4c
highlight  Syntax highlighting for HTML on command line  http://www.andre-simon.de/doku/highlight/en/highlight.php
```

## Copyright and Licensing

This package is copyrighted by [Joshua 'joshuas3'
Stockin](https://joshstock.in/) and licensed under the [MIT License](LICENSE).

&lt;<https://joshstock.in>&gt; | josh@joshstock.in | joshuas3#9641
