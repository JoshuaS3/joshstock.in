const http = require('http');
const fs = require('fs');
const config = require('./config');
const pathFix = require('./pathFix');
const template = require('./templates');
const pages = require('./pages');

const listenerFunction = function(request, response) {
	if (request.url in config.static) { // static file
		response.setHeader('Content-Type', config.static[request.url].type);
		response.writeHead(200);
		response.write(fs.readFileSync(pathFix(config.static[request.url].path), 'utf-8'));
		response.end();
		return;
	}
	if (request.url == '/') { // index
		response.setHeader('Content-Type', 'text/html');
		response.writeHead(200);
		response.write(pages.index());
		response.end();
		return;
	}
	if (request.url.match('^\/.*\/[0-9]*$')) { // /reponame/pagenumber
		repositoryName = request.url.split('/')[1];
		if (repositoryName in config.repositories) {
			pageNumber = request.url.split('/')[2];
			page = pages.repository(repositoryName, pageNumber);
			if (page) {
				response.setHeader('Content-Type', 'text/html');
				response.writeHead(200);
				response.write(page);
			} else {
				response.writeHead(404);
			}
			response.end();
			return;
		}
	}
	response.writeHead(404);
	response.end();
	return;
}

const server = http.createServer(listenerFunction);
server.listen(config.port);
