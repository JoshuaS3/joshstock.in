const fs = require("fs");
const path = require("path");
const express = require("express");
const app = express();
const port = 8080;

let indexHTML = fs.readFileSync(path.resolve(__dirname, "index.html"), "utf8");
let styleCSS = fs.readFileSync(path.resolve(__dirname, "style.css"), "utf8");
app.get("/", function (req, res) {
	res.type("html");
	res.send(indexHTML);
});
app.get("/style.css", function (req, res) {
	res.type("text/css");
	res.send(styleCSS);
});

app.listen(port);
