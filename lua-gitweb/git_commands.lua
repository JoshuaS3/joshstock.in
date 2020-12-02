-- git_commands.lua
-- Index of git commands used for the git status site

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://github.com/JoshuaS3/joshstock.in>
-- <https://joshstock.in>


local utils = require("utils")

local _M = {}

local git = function(repo_dir, command)
    local formatted_command = string.format(
        "/usr/bin/git --git-dir=%s/.git --work-tree=%s %s",
        repo_dir, repo_dir, command
    )
    return utils.process(formatted_command)
end

_M.get_head = function(repo_dir)
    local head = {}
    local name = string.trim(git(repo_dir, "rev-parse --abbrev-ref HEAD"))
    local output = git(repo_dir, "show-ref --heads "..name)
    local a = string.split(string.trim(output), " ")
    head.hash = a[1]
    head.shorthash = string.sub(a[1], 1, 7)
    head.full = a[2]
    head.name = name
    return head
end

_M.diffstat = function(repo_dir, hash)
    hash = hash or "@"
    local output = git(repo_dir, "diff --numstat --shortstat "..hash.."^ --")
    local stat = {}
    local a = string.split(output, "\n")
    table.remove(a,#a)
    stat.shortstat = a[#a]
    table.remove(a,#a)
    stat.plus = 0
    stat.minus = 0
    stat.files = {}
    for i,v in pairs(a) do
        local b = string.split(v,"\t")
        local f = {}
        f.plus = tonumber(b[1])
        stat.plus = stat.plus + f.plus
        f.minus = tonumber(b[2])
        stat.minus = stat.minus + f.minus
        stat.files[b[3]] = f
    end
    return stat
end

_M.count = function(repo_dir, hash)
    hash = hash or "@"
    local output = git(repo_dir, "rev-list --count "..hash.." --")
    return tonumber(string.trim(output))
end

_M.log = function(repo_dir, hash, number, skip, gpg)
    hash = hash or "@"
    number = tostring(number or 25)
    skip = tostring(skip or 0)
    gpg = gpg or false
    local output
    if gpg then
        output = git(repo_dir, "log --pretty=tformat:'%x00%x01%H%x00%cI%x00%cn%x00%ce%x00%s%x00%b%x00%G?%x00%GK%x00%GG%x00' --numstat -n "..number.." --skip "..skip.." "..hash.." --")
    else
        output = git(repo_dir, "log --pretty=tformat:'%x00%x01%H%x00%cI%x00%cn%x00%ce%x00%s%x00%b%x00' --numstat -n "..number.." --skip "..skip.." "..hash.." --")
    end
    local commits = {}
    local a = string.split(output,"\0\1")
    local f = false
    for i,v in pairs(a) do
        if f == true then
            local commit = {}
            local c = string.split(v, "\0")
            commit.hash = c[1]
            commit.shorthash = string.sub(c[1], 1,7)
            commit.timestamp = c[2]
            commit.author = c[3]
            commit.email = c[4]
            commit.subject = c[5]
            commit.body = string.trim(c[6])
            local diffs
            if gpg then
                commit.gpggood = c[7]
                commit.gpgkey = c[8]
                commit.gpgfull = string.trim(c[9])
                diffs = string.trim(c[10])
            else
                diffs = string.trim(c[7])
            end
            commit.diff = {}
            local b = string.split(diffs, "\n")
            commit.diff.plus = 0
            commit.diff.minus = 0
            commit.diff.files = {}
            for i,v in pairs(b) do
                local d = string.split(v,"\t")
                local x = {}
                x.plus = tonumber(d[1]) or 0
                commit.diff.plus = commit.diff.plus + x.plus
                x.minus = tonumber(d[2]) or 0
                commit.diff.minus = commit.diff.minus + x.minus
                commit.diff.files[d[3]] = x
            end
            table.insert(commits, commit)
        else
            f = true
        end
    end
    return commits
end

_M.number = function(repo_dir, hash)
    hash = hash or "@"
    local output = git(repo_dir, "rev-list --count "..hash.." --")
end

_M.commit = function(repo_dir, hash)
    local commit = _M.log(repo_dir, hash, 1, 0)[1]
    commit.number = _M.number(repo_dir, hash)
    return commit
end

_M.heads = function(repo_dir)
    local output = git(repo_dir, "show-ref --heads")
    local a = string.split(output, "\n")
    table.remove(a,#a)
    local heads = {}
    for i,v in pairs(a) do
        local b = string.split(v, " ")
        local head = {}
        head.hash = b[1]
        head.shorthash = string.sub(b[1], 1, 7)
        head.full = b[2]
        head.name = string.split(b[2], "/")[3]
        table.insert(heads, head)
    end
    return heads
end

_M.tags = function(repo_dir)
    local output = git(repo_dir, "show-ref --tags")
    local a = string.split(output, "\n")
    table.remove(a,#a)
    local tags = {}
    for i,v in pairs(a) do
        local b = string.split(v, " ")
        local tag = {}
        tag.hash = b[1]
        tag.shorthash = string.sub(b[1], 1, 7)
        tag.full = b[2]
        tag.name = string.split(b[2], "/")[3]
        table.insert(tags, tag)
    end
    return tags
end

_M.list_refs = function(repo_dir)
    local refs = {}
    refs.heads = _M.heads(repo_dir)
    refs.tags = _M.tags(repo_dir)
    return refs
end

return _M
