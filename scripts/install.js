#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const readline = require("node:readline");

const SKILL = "swarm";
const SOURCE_ROOT = path.resolve(__dirname, "..");
const IGNORED = new Set([".git", "node_modules"]);

// ── Parse arguments ───────────────────────────────────
let force = false;
let yes = false;
const extraDirs = [];
const args = process.argv.slice(2);

for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case "--force":
    case "-f":
      force = true;
      break;
    case "--yes":
    case "-y":
      yes = true;
      break;
    case "--dir":
      if (!args[i + 1]) {
        console.error("Error: --dir requires a path");
        process.exit(1);
      }
      extraDirs.push(args[++i]);
      break;
    case "-h":
    case "--help":
      console.log(
        [
          "Swarm Skill Installer (npx)",
          "",
          "Usage: swarm-skill-install [options]",
          "",
          "Options:",
          "  --yes, -y       Skip menu, install to all detected agents",
          "  --force, -f     Overwrite existing installations",
          "  --dir <path>    Add a custom skills directory",
          "  -h, --help      Show this help",
        ].join("\n"),
      );
      process.exit(0);
    default:
      if (args[i].startsWith("--dir=")) {
        extraDirs.push(args[i].slice(6));
      }
  }
}

// ── Colors ────────────────────────────────────────────
const useColor = process.stdout.isTTY;
const c = {
  bold: useColor ? "\x1b[1m" : "",
  dim: useColor ? "\x1b[2m" : "",
  green: useColor ? "\x1b[32m" : "",
  cyan: useColor ? "\x1b[36m" : "",
  yellow: useColor ? "\x1b[33m" : "",
  red: useColor ? "\x1b[31m" : "",
  reset: useColor ? "\x1b[0m" : "",
};

// ── Detect agents ─────────────────────────────────────
const home = os.homedir();
const agents = [];

function addAgent(name, skillsDir) {
  if (agents.some((a) => a.skillsDir === skillsDir)) return;
  agents.push({ name, skillsDir, selected: true });
}

if (fs.existsSync(path.join(home, ".claude"))) {
  addAgent("Claude Code", path.join(home, ".claude", "skills"));
}

const codexHome = process.env.CODEX_HOME || path.join(home, ".codex");
if (fs.existsSync(codexHome)) {
  addAgent("Codex", path.join(codexHome, "skills"));
}

for (const d of extraDirs) {
  addAgent(`Custom (${d})`, path.resolve(d));
}

if (agents.length === 0) {
  console.error(`${c.red}No agent directories detected.${c.reset}`);
  console.error(
    `Use ${c.bold}--dir <path>${c.reset} to specify a skills directory.`,
  );
  process.exit(1);
}

// ── Copy helper ───────────────────────────────────────
function copyDir(from, to) {
  for (const entry of fs.readdirSync(from, { withFileTypes: true })) {
    if (IGNORED.has(entry.name)) continue;
    const src = path.join(from, entry.name);
    const dst = path.join(to, entry.name);
    if (entry.isDirectory()) {
      fs.mkdirSync(dst, { recursive: true });
      copyDir(src, dst);
    } else {
      fs.copyFileSync(src, dst);
    }
  }
}

// ── Interactive menu ──────────────────────────────────
let prevLines = 0;

function renderMenu(cursor) {
  // erase previous draw
  if (prevLines > 0) {
    for (let i = 0; i < prevLines; i++) {
      process.stdout.write("\x1b[A\x1b[2K");
    }
  }

  const lines = [
    "",
    `  ${c.bold}Swarm Skill Installer${c.reset}`,
    "",
    `  ${c.dim}SPACE${c.reset} toggle  ${c.dim}↑↓${c.reset} move  ${c.dim}ENTER${c.reset} confirm  ${c.dim}q${c.reset} quit`,
    "",
  ];

  for (let i = 0; i < agents.length; i++) {
    const a = agents[i];
    const check = a.selected ? `${c.green}✔${c.reset}` : " ";
    const ptr = i === cursor ? `${c.cyan}❯${c.reset} ` : "  ";
    const target = path.join(a.skillsDir, SKILL);
    const exists = fs.existsSync(target)
      ? `  ${c.yellow}(exists)${c.reset}`
      : "";
    lines.push(
      `  ${ptr}[${check}] ${c.bold}${a.name}${c.reset}  ${c.dim}${target}${c.reset}${exists}`,
    );
  }

  lines.push("");
  process.stdout.write(lines.join("\n") + "\n");
  prevLines = lines.length;
}

function runMenu() {
  return new Promise((resolve) => {
    let cursor = 0;

    // hide cursor
    process.stdout.write("\x1b[?25l");
    const showCursor = () => process.stdout.write("\x1b[?25h");
    process.on("exit", showCursor);

    readline.emitKeypressEvents(process.stdin);
    process.stdin.setRawMode(true);
    process.stdin.resume();

    renderMenu(cursor);

    process.stdin.on("keypress", (_str, key) => {
      if (!key) return;

      if ((key.ctrl && key.name === "c") || key.name === "q") {
        showCursor();
        console.log("  Cancelled.");
        process.exit(0);
      }

      if (key.name === "up" && cursor > 0) {
        cursor--;
      } else if (key.name === "down" && cursor < agents.length - 1) {
        cursor++;
      } else if (key.name === "space") {
        agents[cursor].selected = !agents[cursor].selected;
      } else if (key.name === "return") {
        showCursor();
        process.stdin.setRawMode(false);
        process.stdin.pause();
        process.stdin.removeAllListeners("keypress");
        resolve();
        return;
      }

      renderMenu(cursor);
    });
  });
}

// ── Main ──────────────────────────────────────────────
async function main() {
  if (!yes && process.stdin.isTTY) {
    await runMenu();
  }

  const selected = agents.filter((a) => a.selected);
  if (selected.length === 0) {
    console.log("  No targets selected.");
    process.exit(0);
  }

  console.log("");

  for (const agent of selected) {
    const target = path.join(agent.skillsDir, SKILL);

    if (fs.existsSync(target)) {
      if (!force) {
        console.log(
          `  ${c.yellow}⚠ ${agent.name}: already exists (use --force)${c.reset}`,
        );
        continue;
      }
      fs.rmSync(target, { recursive: true, force: true });
    }

    fs.mkdirSync(target, { recursive: true });
    copyDir(SOURCE_ROOT, target);
    console.log(
      `  ${c.green}✔${c.reset} ${c.bold}${agent.name}${c.reset}  ${c.dim}${target}${c.reset}`,
    );
  }

  console.log(`\n  ${c.green}${c.bold}Done!${c.reset}\n`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
