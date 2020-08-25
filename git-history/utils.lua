-- utils.lua
-- basic utilities for git status site implementation

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://github.com/JoshuaS3/joshstock.in>
-- <https://joshstock.in>


string.split = function(str, delimiter)
    local t = {}
    if not str or str == "" then
        return t
    end
    if delimiter == "" then -- string to table
        string.gsub(str, ".", function(c) table.insert(t, c) end)
        return t
    end
    delimiter = delimiter or "%s"
    local str_len = string.len(str)
    local ptr = 1
    while true do
        local sub = string.sub(str, ptr, str_len)
        local pre, after = string.find(sub, delimiter)
        if pre then -- delimiter found
            table.insert(t, string.sub(str, ptr, ptr + (pre - 2)))
            ptr = ptr + after
        else -- delimiter not found
            table.insert(t, string.sub(str, ptr, str_len))
            break
        end
    end
    return t
end


string.trim = function(str)
    return str:match('^()%s*$') and '' or str:match('^%s*(.*%S)')
end
