const fs = require('fs');
const pathFix = require('./pathFix');
const config = require('./config');

module.exports = function(template, keys) {
	for (key in keys) {
		value = keys[key];
		template = template.replace(new RegExp("\\$" + key, "g"), value);
	}
	return template;
}
