profess = {}

if not ngx then
    print("FATAL ERROR: no ngx module. Are you using ngx_lua (OpenResty)?")
    return 1
end

profess.version_major = 0
profess.version_minor = 1
profess.version_patch = 0
profess.version_string = string.format("profess/%d.%d.%d", profess.version_major, profess.version_minor, profess.version_patch)

ngx.header.Content_Type = "text/html"
ngx.header.Server = profess.version_string
ngx.say("<html><head><title>aaaaa</title></head><body>")
ngx.say("<h1>hello from " .. profess.version_string .. "</h1>")
ngx.say("<p>Running Lua version " .. _VERSION .." (LuaJIT)</p>")
ngx.say("<p>Running nginx version " .. string.format("%d.%d.%d", ngx.config.nginx_version/1000000, ngx.config.nginx_version/1000%1000, ngx.config.nginx_version%1000) .."</p>")
ngx.say("<p>Running ngx_lua version " .. string.format("%d.%d.%d", ngx.config.ngx_lua_version/1000000, ngx.config.ngx_lua_version/1000%1000, ngx.config.nginx_version%1000) .."</p>")
ngx.say("<p>nginx worker " .. tostring(ngx.worker.pid()) .. "</p>")
for i=0,1000 do ngx.say("a") end
ngx.say("</body></html>")
ngx.exit(ngx.HTTP_OK)

local profess = require("profess")
local app = profess.app()

app.authorize("")

app.rewrite("^/(.*)/$", "/$1") -- rewrite trailing slashes

app.route("/", function(req, res)
    res.status = 200
    res.head.content_type = "text/html"

    res.write("<h1>Hello, World!</h1>")

    res.write("<h2>Server Diagnostics</h2>", endl='') -- no newline
    res.write("<p>Running profess version "..profess.version..", "
              .."nginx version "..app.nginx_version..", "
              .."Lua version "..app.lua_version..", "
              .."ngx_lua version "..app.ngx_lua_version.."</p>")
    res.write("<p>nginx worker ID "..tostring(app.worker.id).."</p>")

    res.write("<h2>Request cookies</h2>")
    for name, value in pairs(req.cookies) do
        res.write(
            string.format("<p>%s: %s</p>", name, value)
        )
    end

    res.finish() -- This relays the response to OpenResty and exits the program
end)

app.route("/", function(req, res) --[[...]] end)        -- all of these
app.route("/", "GET", function(req, res) --[[...]] end) -- calls are the
app.get("/", function(req, res) --[[...]] end)          -- same

app.code_route("/api", 404, function(req, res) --[[...]] end)
app.code_route("/api", 405, function(req, res) --[[...]] end)
app.code_default(404, function(req, res) --[[...]] end)
app.code_default(405, function(req, res) --[[...]] end)

app.exit() -- handle cleanup and then exit, if app hasn't already
