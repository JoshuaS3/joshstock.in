-- git_commands.lua
-- Index of git commands used for the git status site

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://github.com/JoshuaS3/joshstock.in>
-- <https://joshstock.in>


local utils = require("utils")


_M = {}


local COMMANDS = {
    get_number = "rev-list --count %s --",
    get_commit = "log %s --pretty=format:'%%aI ## %%H ## %%an ## %%ae ## %%s ## %%b' -n 1 --",
    get_branches = "branch --list --format='%(refname:lstrip=2)'",
    list_commits = "log %s --pretty=format:'%%aI ## %%H ## %%an ## %%ae ## %%s' -n %d --skip=%d --",
    get_diff = "show --pretty='' --numstat %s"
}


local execute = function(repo_dir, command)
    local formatted_command = string.format(
        "git --git-dir=%s/.git --work-tree=%s %s",
        repo_dir, repo_dir, command
    )
    local output
    local status, err = pcall(function()
        local process = io.popen(formatted_command, "r")
        assert(process, "Error opening git process")
        output = process:read("*all")
        process:close()
    end)
    if status then
        return output
    else
        return string.format("Error in git call: %s", err or "")
    end
end


local format_commit = function(commit_string, repo_dir, branch)
    local raw_out = string.split(commit_string, " ## ")
    local commit = {}
    commit.date = raw_out[1]
    commit.hash = raw_out[2]
    commit.author = raw_out[3]
    commit.email = raw_out[4]
    commit.subject = raw_out[5]
    commit.body = raw_out[6]
    return commit
end


_M.get_number = function(repo_dir, commit_hash)
    commit_hash = commit_hash or "HEAD"
    local command = string.format(COMMANDS.get_number, commit_hash)
    local raw_out = execute(repo_dir, command)
    return tonumber(raw_out)
end


_M.get_commit = function(repo_dir, branch)
    branch = branch or "HEAD"
    local command = string.format(COMMANDS.get_commit, branch)
    local raw_out = execute(repo_dir, command)
    local commit = format_commit(raw_out)
    commit.branch = branch
    commit.number = _M.get_number(repo_dir, branch)
    return commit
end


_M.get_diff = function(repo_dir, branch)
    branch = branch or "HEAD"
    local command = string.format(COMMANDS.get_diff, branch)
    local raw_out = string.trim(execute(repo_dir, command))
    local diffs = {}
    diffs.delta = 0
    diffs.max = 0
    diffs.files = {}
    local files = string.split(raw_out, "\n")
    for _, file in pairs(files) do
        local diff = {}
        local stats = string.split(file, "\t")
        diff.plus = stats[1]
        diff.minus = stats[2]
        diff.file = stats[3]
        table.insert(diffs.files, diff)
        local total = diff.plus + diff.minus
        local delta = diff.plus - diff.minus
        if diffs.max < total then
            diffs.max = total
        end
        diffs.delta = diffs.delta + delta
    end
    return diffs
end


_M.get_branches = function(repo_dir)
    local raw_out = execute(repo_dir, COMMANDS.get_branches)
    local trimmed = string.trim(raw_out)
    return string.split(trimmed, "\n")
end


_M.list_commits_by_page = function(repo_dir, branch, page_num, commits_per_page)
    branch = branch or "HEAD"
    page_num = page_num or 1
    commits_per_page = commits_per_page or 32
    local skip = commits_per_page * (page_num - 1)
    local command = string.format(COMMANDS.list_commits, branch, commits_per_page, skip)
    local raw_out = string.trim(execute(repo_dir, command))
    local commits = {}
    for _, line in pairs(string.split(raw_out, "\n")) do
        local commit = format_commit(line)
        commit.branch = branch
        commit.number = _M.get_number(repo_dir, commit.hash)
        table.insert(commits, commit)
    end
    return commits
end


return _M
