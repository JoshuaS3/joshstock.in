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
		let date = commitTime.toLocaleDateString('en-US', {month:'short',day:'numeric',year:'numeric',hour:'numeric',minute:'numeric',second:'numeric'}) + ' (latest commit)';

		let latest = template(config.templates.inline_commit, {'name': name, 'hash': commit.hash, 'shorthash': stats, 'date': date, 'subject': commit.subject, 'author': commit.author, 'email': commit.email});
		let listing = template(config.templates.inline_repository, {'name': name, 'description': repository.description, 'github': repository.github, 'latest': latest});

		repoListings += listing;
	}
	return template(config.templates.index, {'repositories': repoListings});
}

function repository(repo, page) {
	let commits = git.listCommits(config.repositories[repo].location, config.repositories[repo].branch, page);
	let commitList = '';
	let lastDate = "";
	for (i in commits) {
		let commit = commits[i];

		let stats = `${commit.hash.substring(0,7)} (${repository.branch}/${commit.number})`;
		let commitTime = new Date(commit.date);
		let date = commitTime.toLocaleDateString('en-US', {month:'short',day:'numeric',year:'numeric',hour:'numeric',minute:'numeric',second:'numeric'});

		let inline = template(config.templates.inline_commit, {'name': repo, 'hash': commit.hash, 'shorthash': stats, 'date': date, 'subject': commit.subject, 'author': commit.author, 'email': commit.email});

		let dayString = commitTime.toLocaleDateString("en-US", {month:"long",day:"numeric",year:"numeric"});
		if (dayString != lastDate) {
			lastDate = dayString;
			commitList += "<h2 class=\"date category\">" + dayString + "</h2>";
		}
		commitList += inline;
	}
	return template(config.templates.repository, {'repo': repo, 'commits': commitList});
}

module.exports = {
	index: index,
	repository: repository
}
