#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const args = process.argv.slice(2);
const force = args.includes("--force");

const dirFlagIndex = args.indexOf("--dir");
let targetRoot = process.env.CODEX_HOME
  ? path.join(process.env.CODEX_HOME, "skills")
  : path.join(os.homedir(), ".codex", "skills");

if (dirFlagIndex !== -1) {
  const dirValue = args[dirFlagIndex + 1];
  if (!dirValue) {
    console.error("Missing value for --dir");
    process.exit(1);
  }
  targetRoot = path.resolve(dirValue);
}

const sourceRoot = path.resolve(__dirname, "..");
const targetDir = path.join(targetRoot, "swarm");
const ignored = new Set([".git", "node_modules"]);

if (fs.existsSync(targetDir)) {
  if (!force) {
    console.error(`Target already exists: ${targetDir}`);
    console.error("Use --force to overwrite.");
    process.exit(1);
  }
  fs.rmSync(targetDir, { recursive: true, force: true });
}

fs.mkdirSync(targetDir, { recursive: true });

copyDir(sourceRoot, targetDir);

console.log(`Installed swarm skill to: ${targetDir}`);

function copyDir(from, to) {
  const entries = fs.readdirSync(from, { withFileTypes: true });

  for (const entry of entries) {
    if (ignored.has(entry.name)) {
      continue;
    }

    const src = path.join(from, entry.name);
    const dst = path.join(to, entry.name);

    if (entry.isDirectory()) {
      fs.mkdirSync(dst, { recursive: true });
      copyDir(src, dst);
      continue;
    }

    fs.copyFileSync(src, dst);
  }
}
