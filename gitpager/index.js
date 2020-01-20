const fs = require("fs");
const path = require("path");
const express = require("express");
const app = express();
const port = 8080;
const gitcontrol = require(path.resolve(__dirname, "gitcontrol"))

const allowed_repos = {"lognestmonster": "dev", "joshstock.in": "master", "auto-plow": "dev"};

function repo_path(repo) {
	if (process.env.NODE_ENV == "production") {
		return "/home/git/" + repo + ".git/";
	} else {
		return "/home/josh/Desktop/" + repo + "/.git";
	}
}

let commitFile = fs.readFileSync(path.resolve(__dirname, "commit.html")).toString();
function format_commit(repo, commit, isgithub=false, islatest=false) {
	commitString = commitFile;
	if (isgithub) {
		commitString = commitString.replace("$shorthash", "<a title=\"GitHub mirror\" href=\"https://github.com/JoshuaS3/" + repo + "/commit/" + commit.hash + "\">" + commit.hash.substring(0,7) + " (" + allowed_repos[repo] + "/" + commit.number + ")</a>");
		commitString = commitString.replace("$onclick", "");
	} else {
		commitString = commitString.replace("$shorthash", commit.hash.substring(0,7) + " (" + allowed_repos[repo] + "/" + commit.number + ")");
		commitString = commitString.replace("$onclick", "onclick=\"window.location='/$repo/$hash'\"");
	}
	commitString = commitString.replace("$repo", repo).replace("$hash", commit.hash)
		.replace("$subject", commit.subject).replace("$author", commit.author).replace("$author_email", commit.author_email);
	commitTime = new Date(commit.date);
	time = commitTime.toDateString().split(" ").slice(1).join(" ") + ", " + commitTime.toLocaleTimeString().split(" ")[0];
	if (islatest) time += " (latest commit)";
	commitString = commitString.replace("$date", time);
	if (commit.body == undefined) {
		commitString = commitString.replace("$body", "");
	} else {
		commitString = commitString.replace("$body", "<pre class=\"message\">" + (commit.body || "[[no commit body]]") + "</pre>");
	}
	return commitString;
}

app.use(express.static(path.resolve(__dirname, "static")))

let indexFile = fs.readFileSync(path.resolve(__dirname, "index.html")).toString();
app.get("/", function(req, res) {
	response = indexFile;
	for (repo in allowed_repos) {
		response = response.replace("$commit_" + repo, format_commit(repo, gitcontrol.get_commit(repo_path(repo), "HEAD", false), false, true));
	}
	res.send(response);
});

let listingFile = fs.readFileSync(path.resolve(__dirname, "list_page.html")).toString();
app.get("/:repo/:page(\\d+)?", function(req, res) {
	if (allowed_repos[req.params.repo] == null) {
		res.status(404).send()
		return;
	}
	req.params.page = parseInt(req.params.page) || 1;

	response = listingFile;

	commits = gitcontrol.list_commits(repo_path(req.params.repo), allowed_repos[req.params.repo], req.params.page-1);
	total = gitcontrol.count_commits(repo_path(req.params.repo));
	if (commits == null) {
		res.send(404);
		return;
	} else {
		commitsFormatted = "";
		lastDate = "";
		for (commit in commits) {
			dateString = new Date(commits[commit].date).toLocaleDateString("en-US", {month:"long",day:"numeric",year:"numeric"});
			if (dateString != lastDate) {
				lastDate = dateString;
				commitsFormatted += "<h2 class=\"date category\">" + dateString + "</h2>";
			}
			commitsFormatted += format_commit(req.params.repo, commits[commit], false, commits[commit].number == total);
		}
		response = response.replace("$commits", commitsFormatted);
		countLast = commits[commits.length-1].number;
		lastPage = "";
		nextPage = "";
		if (req.params.page > 1) {
			lastPage = `<a href="/${req.params.repo}/${req.params.page-1}" style="margin-right:10px;"><< previous page</a>`;
		}
		if (countLast > 1) {
			nextPage = `<a href="/${req.params.repo}/${req.params.page+1}" style="margin-right:10px;">next page >></a>`;
		}
		if (lastPage != "" || nextPage != "") {
			response = response.replace(/\$pagecontrols/g, `<p style="text-align:center">${lastPage}${nextPage}</p>`);
		}
	}
	response = response.replace(/\$repo/g, req.params.repo);
	stats = `on branch ${allowed_repos[req.params.repo]} with ${total} commits`;
	response = response.replace("$stats", stats);

	res.send(response);
});

let commitPage = fs.readFileSync(path.resolve(__dirname, "commit_page.html")).toString();
app.get("/:repo/:commit([a-f0-9]{40})", function(req, res) {
	if (allowed_repos[req.params.repo] == null) {
		res.status(404).send()
		return;
	}
	commit = gitcontrol.get_commit(repo_path(req.params.repo), req.params.commit);
	if (commit == null) res.send(404);
	response = commitPage;
	response = response.replace(/\$repo/g, req.params.repo);
	response = response.replace(/\$hash/g, commit.hash);
	response = response.replace(/\$shorthash/g, commit.hash.substring(0,7));
	response = response.replace(/\$subject/g, commit.subject);
	total = gitcontrol.count_commits(repo_path(req.params.repo));
	response = response.replace("$commit", format_commit(req.params.repo, commit, true, commit.number == total));
	res.send(response);
});

app.listen(port);
