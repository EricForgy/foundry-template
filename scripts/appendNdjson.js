// scripts/appendNdjson.js
const fs = require("fs");

const filePath = process.argv[2]; // first arg: output path
const entry = JSON.parse(process.argv[3]); // second arg: JSON string

fs.appendFileSync(filePath, JSON.stringify(entry) + "\n");
