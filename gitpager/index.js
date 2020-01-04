const fs = require("fs");
const path = require("path");
const express = require("express");
const app = express();
const port = 8080;

app.use(express.static(path.resolve(__dirname, "static")))
let indexFile = path.resolve(__dirname, "index.html")
app.get("/", function (req, res) {
	res.sendFile(indexFile);
});

app.listen(port);
