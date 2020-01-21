const fs = require('fs');
const yaml = require('js-yaml');
const pathFix = require('./pathFix');

const config_path = 'misc/config.yaml';
const config = yaml.safeLoad(fs.readFileSync(pathFix(config_path), 'utf-8'));

var templates = {};
for (i in config.templates) {
	template = config.templates[i];
	templates[template.name] = fs.readFileSync(pathFix(template.path), 'utf-8');
}

var repositories = {};
for (i in config.repositories) {
	repository = config.repositories[i];
	repositories[repository.name] = {
		description: repository.description,
		branch: repository.branch,
		branches: repository.allows,
		github: repository.github,
		location: repository.location[process.env.NODE_ENV == "production" ? "prod" : "dev"]
	};
}

module.exports = {
	port: config["server-port"],
	static: config.static,
	templates: templates,
	repositories: repositories
};
