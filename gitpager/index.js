const fs = require("fs");
const path = require("path");
const express = require("express");
const app = express();
const port = 8080;

app.use(express.static(path.resolve(__dirname, "static")))

app.listen(port);
