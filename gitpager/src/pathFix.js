const path = require('path');
const rootDir = path.resolve(__dirname, "..");

module.exports = function(local) {
	return path.resolve(rootDir, local);
}
