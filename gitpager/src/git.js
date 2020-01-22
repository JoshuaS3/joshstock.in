const child_process = require('child_process');

function execute(repository, command) {
	return child_process.execSync(`git --git-dir=${repository} ${command}`).toString();
}

function getCommitNumber(repository, hash) {
	return parseInt(execute(repository, `rev-list --count ${hash} --`).trim());
}

function getCommitDiff(repository, hash) {
	let diff = execute(repository, `show --pretty="" --numstat ${hash} --`).trim().split('\n');
	return diff;
}

function getLatestCommit(repository, branch) {
	let commit_raw;
	try {
		commit_raw = execute(repository, `log ${branch || 'HEAD'} --pretty=format:'%aI ## %H ## %an ## %ae ## %s ## %b' -n 1 --`).split(' ## ');
	} catch {
		return null;
	}
	let commit = {};
	commit.date = commit_raw[0];
	commit.hash = commit_raw[1];
	commit.number = getCommitNumber(repository, commit.hash);
	commit.author = commit_raw[2];
	commit.email = commit_raw[3];
	commit.subject = commit_raw[4];
	commit.body = commit_raw[5];
	return commit;
}

function listCommits(repository, branch, page) {
	let commits_raw = execute(repository, `log ${branch} --pretty=format:'%aI ## %H ## %an ## %ae ## %s' -n 20 --skip=${20*(page-1)} --`).trim();
	if (commits_raw.length == 0) return null;
	commits_raw = commits_raw.split('\n');
	let commits = [];
	for (line in commits_raw) {
		let commit_raw = commits_raw[line].split(' ## ');
		let commit = {};
		commit.date = commit_raw[0];
		commit.hash = commit_raw[1];
		commit.number = getCommitNumber(repository, commit.hash);
		commit.author = commit_raw[2];
		commit.email = commit_raw[3];
		commit.subject = commit_raw[4];
		commits.push(commit);
	}
	return commits;
}

module.exports = {
	getCommitDiff: getCommitDiff,
	getCommitNumber: getCommitNumber,
	getLatestCommit: getLatestCommit,
	listCommits: listCommits
}
