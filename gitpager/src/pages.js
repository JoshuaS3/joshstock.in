const config = require('./config');
const template = require('./templates');
const git = require('./git');

function index() {
	let repoListings = '';
	for (name in config.repositories) {
		let repository = config.repositories[name];

		let commit = git.getLatestCommit(repository.location, repository.branch);
		let stats = `${commit.hash.substring(0,7)} (${repository.branch}/${commit.number})`;
		let commitTime = new Date(commit.date);
		let date = commitTime.toLocaleDateString('en-US', {timeZone:'America/Chicago',hourCycle:'h24',month:'short',day:'numeric',year:'numeric',hour:'numeric',minute:'numeric',second:'numeric'}) + ' (latest commit)';

		let latest = template(config.templates.inline_commit, {'name': name, 'hash': commit.hash, 'shorthash': stats, 'date': date, 'subject': commit.subject, 'author': commit.author, 'email': commit.email});
		let listing = template(config.templates.inline_repository, {'name': name, 'description': repository.description, 'github': repository.github, 'latest': latest});

		repoListings += listing;
	}
	return template(config.templates.index, {'repositories': repoListings});
}

function repository(repo, page) {
	let branch = config.repositories[repo].branch;
	let commits = git.listCommits(config.repositories[repo].location, branch, page);
	if (commits == null) return null;
	let commitList = '';
	let lastDate = '';
	for (i in commits) {
		let commit = commits[i];

		let stats = `${commit.hash.substring(0,7)} (${branch}/${commit.number})`;
		let commitTime = new Date(commit.date);
		let date = commitTime.toLocaleDateString('en-US', {timeZone:'America/Chicago',hourCycle:'h24',month:'short',day:'numeric',year:'numeric',hour:'numeric',minute:'numeric',second:'numeric'});

		let inline = template(config.templates.inline_commit, {'name': repo, 'hash': commit.hash, 'shorthash': stats, 'date': date, 'subject': commit.subject, 'author': commit.author, 'email': commit.email});

		let dayString = commitTime.toLocaleDateString('en-US', {month:'long',day:'numeric',year:'numeric'});
		if (dayString != lastDate) {
			lastDate = dayString;
			commitList += '<h2 class=\"date category\">' + dayString + '</h2>';
		}
		commitList += inline;
	}
	let pagePrevious;
	let pageNext;
	if (page > 1) {
		pagePrevious = `<a href="/${repo}/${page-1}" style="margin-right:10px;"><< previous page</a>`;
	}
	if (commits[commits.length-1].number > 1) {
		pageNext = `<a href="/${repo}/${page+1}" style="margin-right:10px;">next page >></a>`;
	}
	pageControls = `<p style="text-align:center">${pagePrevious || ""}${pageNext || ""}</p>`
	let commitCount = git.getCommitNumber(config.repositories[repo].location, branch);
	let stats = `on branch ${branch} with ${commitCount} commits`;
	return template(config.templates.repository, {'repo': repo, 'commits': commitList, 'pagecontrols': pageControls, 'stats': stats, 'github': config.repositories[repo].github});
}

function commit(repo, hash) {
	let repositoryConfig = config.repositories[repo];
	let commit = git.getLatestCommit(repositoryConfig.location, hash);
	if (commit == null) return null;
	let commitTime = new Date(commit.date);
	let date = commitTime.toLocaleDateString('en-US', {timeZone:'America/Chicago',hourCycle:'h24',month:'short',day:'numeric',year:'numeric',hour:'numeric',minute:'numeric',second:'numeric'});
	let stats = `${hash.substring(0,7)} (${repositoryConfig.branch}/${commit.number})`
	let commitCount = git.getCommitNumber(repositoryConfig.location, repositoryConfig.branch);
	let repoStats = `on branch ${repositoryConfig.branch} with ${commitCount} commits`;
	let diff = git.getCommitDiff(repositoryConfig.location, commit.hash);
	let max = 0;
	for (change in diff) {
		diff[change] = diff[change].split('\t');
		diff[change][0] = parseInt(diff[change][0]);
		diff[change][1] = parseInt(diff[change][1]);
		let sum = diff[change][0] + diff[change][1];
		if (sum > max) {
			max = sum;
		}
	}
	let diffString = '';
	for (change in diff) {
		let thisDiff = '';
		thisDiff += diff[change][2] + ' ';
		let plusCount = 0;
		if (diff[change][0] + diff[change][1] < 60) {
			if (diff[change][0] > 0) {
				thisDiff += '<span style="color:lawngreen">' + '+'.repeat(diff[change][0]) + '</span>';
			}
			if (diff[change][1] > 0) {
				thisDiff += '<span style="color:red">' + '-'.repeat(diff[change][1]) + '</span>';
			}
		} else {
			if (diff[change][0] > 0) {
				thisDiff += '<span style="color:lawngreen">' + '+'.repeat(Math.floor(((diff[change][0] || 1)/max)*60)) + '</span>';
			}
			if (diff[change][1] > 0) {
				thisDiff += '<span style="color:red">' + '-'.repeat(Math.floor(((diff[change][1] || 1)/max)*60)) + '</span>';
			}
		}
		thisDiff += '</span>';
		diffString += `${thisDiff}\n`
	}
	return template(config.templates.commit, {'repo': repo, 'github': repositoryConfig.github, 'statsRepo': repoStats, 'shorthash': stats, 'hash': hash, 'date': date, 'subject': commit.subject, 'author': commit.author, 'email': commit.email, 'body': commit.body || '[[no commit body]]', 'diffs': diffString});
}

module.exports = {
	index: index,
	repository: repository,
	commit: commit
}
