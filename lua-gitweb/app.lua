local utils = require("utils")
local git = require("git_commands")

ngx.say([[<style>
*{
    box-sizing:border-box;
}
body{
    font-family:sans-serif;
}
.container>h3{
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
table{
    width:100%;
    border-collapse:collapse;
    overflow:auto;
    font-family:monospace;
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
.q{
    text-decoration:underline;
    text-decoration-style:dotted;
}
.q:hover{
    cursor:help;
}
tr:hover,th{ /*darker color for table head, hovered-over rows*/
    background-color:#dedede;
}
.container{
    max-width: 1000px;
    margin:20px auto;
}
.readme{
    width:100%;
    padding:20px 50px;
    border:1px solid #858585;
    border-top:none;
    border-radius:0 0 6px 6px;
}
img{
    max-width:100%;
}
pre{
    background-color:#eee;
    padding:15px;
    overflow-x:auto;
}
:not(pre)>code{
    background-color:#eee;
    padding:2px;
}
.gpggood {
    font-weight: bold;
    color: slategray;
}
.gpggood-G {
    color: green;
}
.gpggood-N {
    color: red;
}
.gpggood-E {
    color: goldenrod
}
td>svg {
    width:1em;
    height:1em;
    vertical-align:middle;
}
</style>]])
ngx.say("<body>")

local print_table
print_table = function(t, l)
    l = l or 0
    local n = 0
    for i,v in pairs(t) do n = n + 1 break end
    if n > 0 then
        ngx.print("{\n")
        for i,v in pairs(t) do
            for i=0,l do ngx.print("    ") end
            ngx.print("<span style='color:red'>",i,"</span>: ")
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

local headname = git.get_head(repo)

ngx.say("<div class=\"container\"><h2>"..name.." / "..headname.name.."</h2>")
ngx.say("<p>&lt; DESCRIPTION GOES HERE &gt;</p>")
ngx.print("<p>")
ngx.print("<a href=\"#\">Refs</a> | ")
ngx.print("<a href=\"#\">Commit Log</a> | ")
ngx.print("<a href=\"#\">Files</a> | ")
ngx.print("<a href=\"#\">README</a> | ")
ngx.print("<a href=\"#\">LICENSE</a>")
ngx.print("</p></div>")

local commits_head = git.log(repo, "@", "", 1, 0, true)
ngx.say("<div class=\"container\"><h3>Latest Commit</h3><table class=\"log\">")
ngx.print("<tr>")
ngx.print("<th>Time</th>")
ngx.print("<th>Hash</th>")
ngx.print("<th>Subject</th>")
ngx.print("<th>Author</th>")
ngx.print("<th>Email</th>")
ngx.print("<th><span class=\"q\" title=\"# of files changed\">#</span></th>")
ngx.print("<th><span class=\"q\" title=\"Insertions\">(+)</span></th>")
ngx.print("<th><span class=\"q\" title=\"Deletions\">(-)</span></th>")
ngx.print([[<th><span class="q" title="GPG signature status
*
G: Good (valid) signature
B: Bad signature
U: Good signature with unknown validity
X: Good signature that has expired
Y: Good signature made by an expired key
R: Good signature made by a revoked key
E: Signature can't be checked (e.g. missing key)
N: No signature">GPG?</span></th>]])
ngx.print("</tr>")
for i,commit in pairs(commits_head) do
    ngx.print("<tr class=\"commit\">")
    ngx.print("<td class=\"timestamp\">",utils.iso8601(commit.timestamp),"</td>")
    ngx.print("<td class=\"hash\"><a class=\"hash\" href=\"/"..name.."/commit/",commit.hash,"\">",commit.shorthash,"</a></td>")
    ngx.print("<td class=\"subject\">",commit.subject,"</td>")
    ngx.print("<td class=\"author\">",commit.author,"</td>")
    ngx.print("<td class=\"email\"><a class=\"email\" href=\"mailto:",commit.email,"\">",commit.email,"</a></td>")
    ngx.print("<td class=\"changed\">",commit.diff.num,"</td>")
    ngx.print("<td class=\"plus\"",commit.diff.plus>commit.diff.minus and " style=\"color:green;font-weight:bold\"" or "",">",commit.diff.plus~=0 and commit.diff.plus or "","</td>")
    ngx.print("<td class=\"minus\"",commit.diff.minus>commit.diff.plus and " style=\"color:red;font-weight:bold\"" or "",">",commit.diff.minus~=0 and commit.diff.minus or "","</td>")
    ngx.print("<td class=\"gpggood gpggood-",commit.gpggood ~= "" and commit.gpggood or "NONE","\">",commit.gpggood,"</td>")
    ngx.say("</tr>")
end
ngx.say("</table>")
ngx.say("</div>")

ngx.say("<div class=\"container\"><h3>Files</h3><table class=\"tree\">")
ngx.print("<tr>")
ngx.print("<th>Object</th><th>Latest Commit Subject</th><th>Time</th><th>Hash</th>")
ngx.say("</tr>")
local files = git.list_tree(repo, "@", "")

local iconfolder = [[<svg viewBox="0 0 24 24" width="12" height="15" stroke="currentColor" stroke-width="2" fill="#FFE9A2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path></svg>]]
local iconfile = [[<svg viewBox="0 0 24 24" width="12" height="15" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path><polyline points="13 2 13 9 20 9"></polyline></svg>]]

for i,v in pairs(files.dirs) do
    ngx.print("<tr>")
    ngx.print("<td>",iconfolder," <a href=\"/",name,"/master/tree/",v,"\">",v,"</a></td>")
    local lastedit = git.log(repo, "@ -1", v, 1, 0, false)[1]
    ngx.print("<td>",lastedit.subject,"</td>")
    ngx.print("<td class=\"timestamp\">",utils.iso8601(lastedit.timestamp),"</td>")
    ngx.print("<td class=\"hash\"><a href=\"",lastedit.hash,"\">",lastedit.shorthash,"</a></td>")
    ngx.say("</tr>")
end
for i,v in pairs(files.files) do
    ngx.print("<tr>")
    ngx.print("<td>",iconfile," <a href=\"/",name,"/master/blob/",v,"\">",v,"</a></td>")
    local lastedit = git.log(repo, "@ -1", v, 1, 0, false)[1]
    ngx.print("<td>",lastedit.subject,"</td>")
    ngx.print("<td class=\"timestamp\">",utils.iso8601(lastedit.timestamp),"</td>")
    ngx.print("<td class=\"hash\"><a href=\"/",name,"/commit/",lastedit.hash,"\">",lastedit.shorthash,"</a></td>")
    ngx.say("</tr>")
end
ngx.say("</table></div>")

ngx.say("<div class=\"container\"><h3 style=\"margin:0;padding:10px;background-color:#dedede;border-radius:6px 6px 0 0;border:1px solid #000\">README</h3><div class=\"readme\">")
local README = git.show_file(repo, "@", "README.md")
ngx.say(utils.markdown(README))
ngx.say("</div></div>")

ngx.say("</body>")

ngx.exit(ngx.HTTP_OK)
