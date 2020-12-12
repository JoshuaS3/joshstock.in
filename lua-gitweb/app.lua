-- app.lua
-- Entry point for git HTTP site implementation

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local lyaml = require("lyaml")
local utils = require("utils")
local git = require("git_commands")
local request = require("request")
local tabulate = require("tabulate")
local html = require("html")

local parsed_uri = request.parse_uri()
local content

if parsed_uri.repo == nil then
    -- home page, list of repositories
else -- repo found
    local repo
    for _,r in pairs(yaml_config) do
        if parsed_uri.repo == r.name then
            repo = r
            break
        end
    end
    if repo then
        local repo_dir = repo.location.dev
        local view = parsed_uri.parts[2] or "tree"
        local branch
        if pcall(function() -- if branch is real
            branch = git.get_head(repo_dir, parsed_uri.parts[3]) -- if parts[3] is nil, defaults to "HEAD"
        end) then
            if view == "tree" then -- directory display (with automatic README rendering)
                -- /repo/tree/branch/[DIRECTORY PATH]

                local path = parsed_uri.parts
                table.remove(path, 3) -- branch
                table.remove(path, 2) -- "tree"
                table.remove(path, 1) -- repo
                if #path > 0 then
                    path = table.concat(path, "/").."/"
                else
                    path = ""
                end

                content = html.tree(repo, repo_dir, branch, path)

            elseif view == "blob" then
                -- /repo/blob/branch/[FILE PATH]
            elseif view == "raw" then
                -- /repo/raw/branch/[FILE PATH]
            elseif view == "log" then
                -- /repo/log/branch?n=[COMMITS PER PAGE]&skip=[COMMITS TO SKIP]

                content = html.log(repo, repo_dir, branch, 40, 0)

            elseif view == "refs" then

                content = html.refs(repo, repo_dir, branch)

            elseif view == "download" then

                content = html.download(repo, repo_dir, branch)

            elseif view == "commit" then
                -- /repo/commit/[COMMIT HASH]
            end
        end
    end
end

if content ~= nil then
ngx.say([[<style>
@import url('https://fonts.googleapis.com/css?family=Fira+Sans:400,400i,700,700i&display=swap');
@import url('https://fonts.googleapis.com/css?family=Fira+Mono:400,400i&display=swap');
*{
box-sizing:border-box;
}
body{
font-family:'Fira Sans', sans-serif;
padding-bottom:200px;
line-height:1.4;
max-width:1000px;
margin:20px auto;
}
body>h2{
    margin-top:5px;
    margin-bottom:0;
}
h3{
margin-bottom:4px;
}
td,th{
padding:2px 5px;
border:1px solid #858585;
text-align:left;
vertical-align:top;
}
th{
border:1px solid #000;
}
table.log,table.files{
    width:100%;
}
table{
border-collapse:collapse;
overflow:auto;
font-family:'Fira Mono', monospace;
font-size:14px;
}
table.log td:not(:nth-child(3)){
max-width:1%;
white-space:nowrap;
}
table.tree td:not(:nth-child(2)){
max-width:1%;
white-space:nowrap;
}
span.q{
text-decoration:underline;
text-decoration-style:dotted;
}
.q:hover{
cursor:help;
}
tr:hover,th{ /*darker color for table head, hovered-over rows*/
background-color:#dedede;
}
div.markdown{
width:100%;
padding:20px 50px;
border:1px solid #858585;
border-radius:6px;
}
img{
max-width:100%;
}
pre{
background-color:#eee;
padding:15px;
overflow-x:auto;
border-radius:8px;
}
:not(pre)>code{
background-color:#eee;
padding:2.5px;
border-radius:4px;
}
a{
text-decoration:none;
color: #0077aa;
}
a:hover{
    text-decoration:underline;
}
</style>]])

    local arrow_left_circle = [[<img style="width:1.2em;height:1.2em;vertical-align:middle;margin-right:0.2em" src="https://joshuas3.s3.amazonaws.com/svg/arrow-left.svg"/>]]
    ngx.say("<a style=\"margin-left:-1.35em\" href=\"/\">"..arrow_left_circle.."<span style=\"vertical-align:middle\">Index</span></a>")
    ngx.say(content.body)
    ngx.exit(ngx.HTTP_OK)
    return
else
    ngx.exit(ngx.HTTP_NOT_FOUND) -- default behavior
    return
end
