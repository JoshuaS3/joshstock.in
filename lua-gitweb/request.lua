-- request.lua
-- URI parsing

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local utils = require("utils")

local _M = {}

_M.parse_uri = function()
    local uri = ngx.var.uri
    local split = string.split(string.sub(uri,2),"/")

    local parsed = {}
    parsed.uri = uri
    parsed.parts = split
    parsed.repo = split[1]

    return parsed
end

return _M
