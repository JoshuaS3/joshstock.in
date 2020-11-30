local utils = require("utils")

ngx.say("<body style=\"max-width:800px;margin:0 auto;overflow:wrap;\">")

local function script_path()
    return debug.getinfo(2, "S").source:sub(2):match("(.*/)")
end

local md2html = function(file)
    local formatted_command = string.format(
        "md2html --github %s",
        file
    )
    local output
    local status, err = pcall(function()
        local process = io.popen(formatted_command, "r")
        assert(process, "Error opening md2html process")
        output = process:read("*a")
        process:close()
    end)
    if status then
        return output
    else
        return string.format("Error in md2html call: %s", err or "")
    end
end

ngx.say("<pre><code>")
ngx.say(ngx.req.raw_header())
ngx.say("</code></pre>")

local readme = script_path().."README.md"
ngx.say(md2html(readme))

ngx.say("</body>")

ngx.exit(ngx.HTTP_OK)
