local utils = require("utils")
local git = require("git_commands")

ngx.say("<style>body{width:1100px;margin:20px auto;font-family:sans-serif}img{max-width:100%}pre{background-color:#eee;padding:8px;overflow-x:auto}:not(pre)>code{background-color:#eee;padding:2px}td,th{padding:2px 5px;border:1px solid #858585;text-align:left;vertical-align:top}table{border-collapse:collapse;font-family:monospace;width:100%}td:not(:nth-child(3)){width:1%;white-space:nowrap}.readme{padding:20px 50px;border:1px solid #ccc}</style>")
ngx.say("<body>")

local md2html = function(file)
    local formatted_command = string.format(
        "/usr/local/bin/md2html --github %s",
        file
    )
    return utils.process(formatted_command)
end

print_table = function(t, l)
    l = l or 0
    local n = 0
    for i,v in pairs(t) do n = n + 1 break end
    if n > 0 then
        ngx.print("{\n")
        for i,v in pairs(t) do
            for i=0,l do ngx.print("    ") end
            ngx.print("<span style='color:red'>",i,": </span>")
            if type(v) ~= "table" then
                if type(v) == "string" then
                    ngx.print("\"")
                    local s = v:gsub("&", "&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
                    ngx.print(s)
                    ngx.print("\"")
                else
                    ngx.print(v)
                end
            else
                print_table(v,l+1)
            end
            ngx.print("\n")
        end
        for i=0,l-1 do ngx.print("    ") end
        ngx.print("}")
    else
        ngx.print("{}")
    end
end

local name = "ncurses-minesweeper"
--local name = "lognestmonster"
--local name = "auto-plow"
--local name = "joshstock.in"
local repo = "/home/josh/repos/"..name
local commits_head = git.log(repo, "@", 10, 0, true)

ngx.say("<h2>"..name.." / master</h2>")
ngx.say("<p>Terminal game of Minesweeper, implemented in C with ncurses.</p>")
ngx.say("<p>Log | Files | Refs | README | LICENSE</p>")
ngx.say("<table>")
ngx.print("<tr>")
ngx.print("<th>Date</th>")
ngx.print("<th>Hash</th>")
ngx.print("<th>Subject</th>")
ngx.print("<th>Author</th>")
ngx.print("<th>Email</th>")
ngx.print("<th>+</th>")
ngx.print("<th>-</th>")
ngx.print("<th>GPG?</th>")
ngx.print("<tr>")
for i,commit in pairs(commits_head) do
    ngx.print("<tr>")
    ngx.print("<td>",utils.iso8601(commit.timestamp),"</td>")
    ngx.print("<td><a href=\"/"..name.."/commit/",commit.hash,"\">",commit.shorthash,"</a></td>")
    ngx.print("<td>",commit.subject,"</td>")
    ngx.print("<td>",commit.author,"</td>")
    ngx.print("<td><a href=\"mailto:",commit.email,"\">",commit.email,"</a></td>")
    ngx.print("<td style=\"color:",commit.diff.plus>commit.diff.minus and "green;font-weight:bold" or "inherit","\">",commit.diff.plus,"</td>")
    ngx.print("<td style=\"color:",commit.diff.minus>commit.diff.plus and "red;font-weight:bold" or "inherit","\">",commit.diff.minus,"</td>")
    ngx.print("<td><b style=\"color:", commit.gpggood=="G" and "green" or "red","\">",commit.gpggood,"</b></td>")
    ngx.say("</tr>")
end
ngx.say("</table>")

ngx.say("<div class=\"readme\">")
ngx.say("<h5>README</h5>")
ngx.say(md2html(repo.."/README.md"))
ngx.say("</div>")

ngx.say("</body>")

ngx.exit(ngx.HTTP_OK)
