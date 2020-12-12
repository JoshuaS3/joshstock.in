-- html.lua
-- Formatting data with HTML

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local lyaml = require("lyaml")
local utils = require("utils")
local git = require("git_commands")
local request = require("request")
local tabulate = require("tabulate")

local create_html_template = function()
    local t = {}
    t.title = ""
    t.meta_tags = {}
    t.body = ""
    return t
end

local tree = function(repo, repo_dir, branch, path)
    local t = create_html_template()

    if path ~= "" then -- make sure path exists
        local path_tree = git.list_tree(repo_dir, branch.name, string.sub(path, 1, path:len() - 1))
        if #path_tree.dirs == 0 then -- no path found
            return nil
        end
    end

    -- Header with repository description and navigation links
    t.body = t.body..string.format([[<h2><a href="/%s">%s</a> / <a href="/%s/tree/%s">%s</a></h2>]], repo.name, repo.name, repo.name, branch.name, branch.name)
    t.body = t.body.."<p>"..repo.description.."</p>"

    local navlinks_list = {
        "<a href=\"/"..repo.name.."/download\">Download</a>",
        "<a href=\"/"..repo.name.."/refs\">Refs</a>",
        "<a href=\"/"..repo.name.."/log/"..branch.name.."\">Commit Log</a>",
        "<b><a href=\"/"..repo.name.."/tree/"..branch.name.."\">Files</a></b>"
    }

    for _, special in pairs(repo.specialfiles) do
        local split = string.split(special, " ")
        table.insert(navlinks_list, string.format([[<a href="/%s/blob/%s/%s">%s</a>]], repo.name, branch.name, split[2], split[1]))
    end

    t.body = t.body.."<p>"..table.concat(navlinks_list, " | ").."</p>"

    -- Latest Commit table
    t.body = t.body.."<h3>Latest Commit</h3>"

    local commits_table_data = {}
    commits_table_data.class = "log"
    commits_table_data.headers = {
        {"timestamp", "Time"},
        {"shorthash", "Hash"},
        {"subject",   "Subject"},
        {"author",    "Author"},
        {"changed_files", [[<span class="q" title="# of files changed">#</span>]]},
        {"changed_plus",  [[<span class="q" title="Insertions">(+)</span>]]},
        {"changed_minus", [[<span class="q" title="Deletions">(-)</span>]]},
        {"gpggood",       [[<span class="q" title="GPG signature status

G: Good (valid) signature
B: Bad signature
U: Good signature with unknown validity
X: Good signature that has expired
Y: Good signature made by an expired key
R: Good signature made by a revoked key
E: Signature can't be checked (e.g. missing key)
N: No signature">GPG?</span>]]}
    }
    commits_table_data.rows = {}

    local commits_head = git.log(repo_dir, branch.name, path, 1, 0, true)

    for _, commit in pairs(commits_head) do
        table.insert(commits_table_data.rows, {
                utils.iso8601(commit.timestamp),
                string.format([[<a href="/%s/commit/%s">%s</a>]], repo.name, commit.hash, commit.shorthash),
                utils.html_sanitize(commit.subject),
                string.format([[<a href="mailto:%s">%s</a>]], commit.email, utils.html_sanitize(commit.author)),
                commit.diff.num,
                commit.diff.plus,
                commit.diff.minus,
                commit.gpggood
            })
    end

    t.body = t.body..tabulate(commits_table_data)

    -- Tree/files table
    t.body = t.body.."<h3>Tree"
    if path == "" then
        t.body = t.body.."</h3>"
    else -- build path with hyperlinks for section header
        local split = string.split(path, "/")
        table.remove(split, #split)
        local base = "/"..repo.name.."/tree/"..branch.name
        t.body = t.body..string.format([[ @ <a href="%s">%s</a>]], base, repo.name)
        local build = ""
        for _, part in pairs(split) do
            build = build.."/"..part
            t.body = t.body..string.format([[ / <a href="%s%s">%s</a>]], base, build, part)
        end
        t.body = t.body.."</h3>"
    end

    local files_table_data = {}
    files_table_data.class = "files"
    files_table_data.headers = {
        {"object",    "Object"},
        {"subject",   "Latest Commit Subject"},
        {"timestamp", "Time"},
        {"shorthash", "Hash"}}
    files_table_data.rows = {}

    local files = git.list_tree(repo_dir, branch.name, path)

    local file_icon   = [[<img style="width:1em;height:1em;vertical-align:middle;margin-right:0.5em;" src="https://joshuas3.s3.amazonaws.com/svg/file.svg"/>]]
    local folder_icon = [[<img style="width:1em;height:1em;vertical-align:middle;margin-right:0.5em;fill:#ffe9a2;" src="https://joshuas3.s3.amazonaws.com/svg/folder.svg"/>]]

    -- .. directory
    if path ~= "" then
        local split = string.split(string.sub(path, 1, path:len() - 1), "/")
        table.remove(split, #split)
        if #split > 0 then -- deeper than 1 directory
            table.insert(files_table_data.rows, {
                    string.format([[%s<a href="/%s/tree/%s/%s">..</a>]], folder_icon, repo.name, branch.name, table.concat(split, "/")),
                    "","",""
                })
        else -- only one directory deep
            table.insert(files_table_data.rows, {
                    string.format([[%s<a href="/%s/tree/%s">..</a>]], folder_icon, repo.name, branch.name),
                    "","",""
                })
        end
    end

    -- Regular directories
    for _, dir in pairs(files.dirs) do
        local lastedit = git.log(repo_dir, branch.name.." -1", dir, 1, 0, false)[1]
        local split = string.split(dir, "/")
        local name = split[#split]
        table.insert(files_table_data.rows, {
                string.format([[%s<a href="/%s/tree/%s/%s">%s</a>]], folder_icon, repo.name, branch.name, dir, name),
                utils.html_sanitize(lastedit.subject),
                utils.iso8601(lastedit.timestamp),
                string.format([[<a href="/%s/commit/%s">%s</a>]], repo.name, lastedit.hash, lastedit.shorthash)
            })
    end

    -- Regular files
    for _, file in pairs(files.files) do
        local lastedit = git.log(repo_dir, branch.name.." -1", file, 1, 0, false)[1]
        local split = string.split(file, "/")
        local name = split[#split]
        table.insert(files_table_data.rows, {
                string.format([[%s<a href="/%s/blob/%s/%s">%s</a>]], file_icon, repo.name, branch.name, file, name),
                utils.html_sanitize(lastedit.subject),
                utils.iso8601(lastedit.timestamp),
                string.format([[<a href="/%s/commit/%s">%s</a>]], repo.name, lastedit.hash, lastedit.shorthash)
            })
    end

    t.body = t.body..tabulate(files_table_data)

    -- Look for and render README if it exists
    for _, file in pairs(files.files) do
        local l = file:lower()
        if l:match("^readme") then
            t.body = t.body.."<h3>README</h3>"
            local text = git.show_file(repo_dir, branch.name, path..file)
            local s = file:len()
            if string.sub(l, s-2, s) == ".md" then
                t.body = t.body..[[<div class="markdown">]]..utils.markdown(text).."</div>"
            else
                t.body = t.body.."<pre><code>"..text.."</code></pre>"
            end
            break
        end
    end

    return t
end

local refs = function(repo, repo_dir, branch)
    local t = create_html_template()

    -- Header with repository description and navigation links
    t.body = t.body..string.format([[<h2><a href="/%s">%s</a> / <a href="/%s/refs">refs</a></h2>]], repo.name, repo.name, repo.name)
    t.body = t.body.."<p>"..repo.description.."</p>"

    local navlinks_list = {
        "<a href=\"/"..repo.name.."/download\">Download</a>",
        "<b><a href=\"/"..repo.name.."/refs\">Refs</a></b>",
        "<a href=\"/"..repo.name.."/log/"..branch.name.."\">Commit Log</a>",
        "<a href=\"/"..repo.name.."/tree/"..branch.name.."\">Files</a>"
    }

    for _, special in pairs(repo.specialfiles) do
        local split = string.split(special, " ")
        table.insert(navlinks_list, string.format([[<a href="/%s/blob/%s/%s">%s</a>]], repo.name, branch.name, split[2], split[1]))
    end

    t.body = t.body.."<p>"..table.concat(navlinks_list, " | ").."</p>"

    local all_refs = git.list_refs(repo_dir)

    -- Branches
    if #all_refs.heads > 0 then
        t.body = t.body.."<h3>Branches</h3>"

        local branches_table_data = {}
        branches_table_data.class = "branches"
        branches_table_data.headers = {
            {"name", "Name"},
            {"ref", "Ref"},
            {"has", "Hash"}
        }
        branches_table_data.rows = {}

        for _, b in pairs(all_refs.heads) do
            table.insert(branches_table_data.rows, {
                    b.name ~= branch.name and b.name or b.name.." <b>(HEAD)</b>",
                    string.format([[<a href="/%s/tree/%s">%s</a>]], repo.name, b.name, b.full),
                    string.format([[<a href="/%s/commit/%s">%s</a>]], repo.name, b.hash, b.shorthash)
                })
        end

        t.body = t.body..tabulate(branches_table_data)
    end

    -- Tags
    if #all_refs.tags > 0 then
        t.body = t.body.."<h3>Tags</h3>"

        local tags_table_data = {}
        tags_table_data.class = "tags"
        tags_table_data.headers = {
            {"name", "Name"},
            {"ref", "Ref"},
            {"has", "Hash"}
        }
        tags_table_data.rows = {}
        for _, t in pairs(all_refs.tags) do
            table.insert(tags_table_data.rows, {
                    t.name ~= branch.name and t.name or t.name.." <b>(HEAD)</b>",
                    string.format([[<a href="/%s/tree/%s">%s</a>]], repo.name, t.name, t.full),
                    string.format([[<a href="/%s/commit/%s">%s</a>]], repo.name, t.hash, t.shorthash)
                })
        end

        t.body = t.body..tabulate(tags_table_data)
    end

    return t
end

local log = function(repo, repo_dir, branch, n, skip)
    n = n or 40
    skip = skip or 0

    local t = create_html_template()

    -- Header with repository description and navigation links
    t.body = t.body..string.format([[<h2><a href="/%s">%s</a> / <a href="/%s/tree/%s">%s</a> / <a href="/%s/log/%s">log</a></h2>]], repo.name, repo.name, repo.name, branch.name, branch.name, repo.name, branch.name)
    t.body = t.body.."<p>"..repo.description.."</p>"

    local navlinks_list = {
        "<a href=\"/"..repo.name.."/download\">Download</a>",
        "<a href=\"/"..repo.name.."/refs\">Refs</a>",
        "<b><a href=\"/"..repo.name.."/log/"..branch.name.."\">Commit Log</a></b>",
        "<a href=\"/"..repo.name.."/tree/"..branch.name.."\">Files</a>"
    }

    for _, special in pairs(repo.specialfiles) do
        local split = string.split(special, " ")
        table.insert(navlinks_list, string.format([[<a href="/%s/blob/%s/%s">%s</a>]], repo.name, branch.name, split[2], split[1]))
    end

    t.body = t.body.."<p>"..table.concat(navlinks_list, " | ").."</p>"

    -- Latest Commit table
    t.body = t.body.."<h3>Commits</h3>"

    local commits_table_data = {}
    commits_table_data.class = "log"
    commits_table_data.headers = {
        {"timestamp", "Time"},
        {"shorthash", "Hash"},
        {"subject",   "Subject"},
        {"author",    "Author"},
        {"changed_files", [[<span class="q" title="# of files changed">#</span>]]},
        {"changed_plus",  [[<span class="q" title="Insertions">(+)</span>]]},
        {"changed_minus", [[<span class="q" title="Deletions">(-)</span>]]},
        {"gpggood",       [[<span class="q" title="GPG signature status

G: Good (valid) signature
B: Bad signature
U: Good signature with unknown validity
X: Good signature that has expired
Y: Good signature made by an expired key
R: Good signature made by a revoked key
E: Signature can't be checked (e.g. missing key)
N: No signature">GPG?</span>]]}
    }
    commits_table_data.rows = {}

    local commits_head = git.log(repo_dir, branch.name, path, n, skip, true)

    for _, commit in pairs(commits_head) do
        table.insert(commits_table_data.rows, {
                utils.iso8601(commit.timestamp),
                string.format([[<a href="/%s/commit/%s">%s</a>]], repo.name, commit.hash, commit.shorthash),
                utils.html_sanitize(commit.subject),
                string.format([[<a href="mailto:%s">%s</a>]], commit.email, utils.html_sanitize(commit.author)),
                commit.diff.num,
                commit.diff.plus,
                commit.diff.minus,
                commit.gpggood
            })
    end

    t.body = t.body..tabulate(commits_table_data)

    return t
end

local download = function(repo, repo_dir, branch)
    local t = create_html_template()

    -- Header with repository description and navigation links
    t.body = t.body..string.format([[<h2><a href="/%s">%s</a> / <a href="/%s/download">download</a></h2>]], repo.name, repo.name, repo.name)
    t.body = t.body.."<p>"..repo.description.."</p>"

    local navlinks_list = {
        "<b><a href=\"/"..repo.name.."/download\">Download</a></b>",
        "<a href=\"/"..repo.name.."/refs\">Refs</a>",
        "<a href=\"/"..repo.name.."/log/"..branch.name.."\">Commit Log</a>",
        "<a href=\"/"..repo.name.."/tree/"..branch.name.."\">Files</a>"
    }

    for _, special in pairs(repo.specialfiles) do
        local split = string.split(special, " ")
        table.insert(navlinks_list, string.format([[<a href="/%s/blob/%s/%s">%s</a>]], repo.name, branch.name, split[2], split[1]))
    end

    t.body = t.body.."<p>"..table.concat(navlinks_list, " | ").."</p>"

    t.body = t.body.."<h3>Download URLs</h3>"

    local urls = {}
    urls.class = "download-urls"
    urls.headers = {
        {"protocol", "Protocol"},
        {"url", "URL"}
    }
    urls.rows = {}

    for _, url in pairs(repo.download) do
        local split = string.split(url, " ")
        table.insert(urls.rows, {split[1], string.format([[<a href="%s">%s</a>]], split[2], split[2])})
    end

    t.body = t.body..tabulate(urls)

    t.body = t.body.."<h3>Websites</h3>"

    local sites = {}
    sites.class = "websites"
    sites.headers = {
        {"name", "Website"},
        {"url", "URL"}
    }
    sites.rows = {}

    for _, site in pairs(repo.urls) do
        local split = string.split(site, " ")
        table.insert(sites.rows, {split[1], string.format([[<a href="%s">%s</a>]], split[2], split[2])})
    end

    t.body = t.body..tabulate(sites)

    return t
end


local _M = {}
_M.tree = tree
_M.refs = refs
_M.log = log
_M.download = download
return _M
