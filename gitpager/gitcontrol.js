const path = require("path");
const child_process = require("child_process");

function exec(commandstring) {
	return child_process.execSync(commandstring).toString();
}

const skip_count = 20;

const count_commits_command = "git --git-dir $REPOSITORY/.git rev-list --count $BRANCH";
function count_commits(repository, branch="HEAD") {
	call = count_commits_command.replace("$REPOSITORY", repository).replace("$BRANCH", branch);
	return exec(call).trim();
}

const get_commit_command = "git --git-dir $REPOSITORY/.git log $BRANCH --pretty=format:'%aI ## %H ## %an ## %ae ## %s ## %b' -n 1 --";
function get_commit(repository, branch="HEAD") {
	call = get_commit_command.replace("$REPOSITORY", repository).replace("$BRANCH", branch);
	properties = exec(call).split(" ## ");
	commit = {};
	commit.number = count_commits(repository, properties[1]);
	commit.date = properties[0];
	commit.hash = properties[1];
	commit.author = properties[2];
	commit.author_email = properties[3];
	commit.subject = properties[4];
	commit.body = properties[5].trim();
	return commit;
}

const list_commits_command = `git --git-dir $REPOSITORY/.git log $BRANCH --pretty=format:'%aI ## %H ## %an ## %ae ## %s' -n ${skip_count} --skip=$SKIP --`;
function list_commits(repository, branch="HEAD", skip=0) {
	call = list_commits_command.replace("$REPOSITORY", repository).replace("$BRANCH", branch).replace("$SKIP", skip*skip_count);
	commits = [];
	lines = exec(call).split("\n");
	if (lines == ['']) return commits;
	for (let i = 0; i < lines.length; i++) {
		properties = lines[i].split(" ## ");
		commit = {};
		commit.number = count_commits(repository, properties[1]);
		commit.date = properties[0];
		commit.hash = properties[1];
		commit.author = properties[2];
		commit.author_email = properties[3];
		commit.subject = properties[4];
		commits.push(commit);
	}
	return commits;
}

module.exports = {
	count_commits: count_commits
	,get_commit: get_commit
	,list_commits: list_commits
}
