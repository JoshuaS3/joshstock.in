const fs = require("fs");
const path = require("path");
const express = require("express");
const app = express();
const port = 8080;
const gitcontrol = require(path.resolve(__dirname, "gitcontrol"))

const allowed_repos = {"lognestmonster": "dev", "joshstock.in": "master", "auto-plow": "dev"};

function repo_path(repo) {
	if (process.env.NODE_ENV == "production") {
		return "/home/git/" + repo + ".git";
	} else {
		return "/home/josh/Desktop/" + repo;
	}
}

commitFile = fs.readFileSync(path.resolve(__dirname, "commit.html")).toString();
function format_commit(repo, commit, isgithub=false, islatest=false) {
	commitString = commitFile.replace("$repo", repo).replace("$hash", commit.hash)
		.replace("$subject", commit.subject).replace("$author", commit.author).replace("$author_email", commit.author_email);
	if (isgithub) {
		commitString = commitString.replace("$shorthash", "<a href=\"https://github.com/JoshuaS3/" + repo + "/commit/" + commit.hash + "\">" + commit.hash.substring(0,7) + " (" + allowed_repos[repo] + "/" + commit.number + ")</a>");
	} else {
		commitString = commitString.replace("$shorthash", commit.hash.substring(0,7) + " (" + allowed_repos[repo] + "/" + commit.number + ")");
	}
	commitTime = new Date(commit.date);
	time = commitTime.toDateString().split(" ").slice(1).join(" ") + ", " + commitTime.toLocaleTimeString().split(" ")[0];
	if (islatest) time += " (latest commit)";
	commitString = commitString.replace("$date", time);
	if (commit.body === undefined) {
		commitString = commitString.replace("$body", commit.body);
	} else {
		commitString = commitString.replace("$body", "");
	}
	return commitString;
}

app.use(express.static(path.resolve(__dirname, "static")))

indexFile = fs.readFileSync(path.resolve(__dirname, "index.html")).toString();
app.get("/", function(req, res) {
	response = indexFile;
	for (repo in allowed_repos) {
		response = response.replace("$commit_" + repo, format_commit(repo, gitcontrol.get_commit(`${repo_path(repo)}`, "@{0}"), false, true));
	}
	res.send(response);
});

app.get("/:repo/:page(\\d+)", function(req, res) {
	if (allowed_repos[req.params.repo] == null) {
		res.status(404).send()
		return;
	}
	req.params.page = parseInt(req.params.page) || 1;
	res.send(gitcontrol.list_commits(`${repo_path(req.params.repo)}`, allowed_repos[req.params.repo], req.params.page-1));
});

app.get("/:repo/:commit([a-f0-9]{40})", function(req, res) {
	if (allowed_repos[req.params.repo] == null) {
		res.status(404).send()
		return;
	}
	res.send(gitcontrol.get_commit(`${repo_path(req.params.repo)}`, req.params.commit));
});

app.listen(port);
