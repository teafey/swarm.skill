# Swarm Skill

`swarm` is a skill for team-based parallel execution across AI coding agents.
Based on Anthropic Agent Teams documentation: https://code.claude.com/docs/en/agent-teams

Русская версия: [README.ru.md](README.ru.md)

## What it does

- Triggers when users ask to run work with a team or in parallel.
- Splits work into 4 scoped agents.
- Enforces plan-first execution and file-scope isolation.
- Requires explicit review, progress tracking, and clean shutdown.

## Repository structure

- `SKILL.md` - full skill instructions and workflow.
- `README.md` - project overview (English).
- `README.ru.md` - обзор проекта (Русский).
- `LICENSE` - MIT license.
- `install.sh` - shell installer with interactive agent picker.
- `scripts/install.js` - Node.js installer (for `npx`).
- `package.json` - npm metadata and CLI entrypoint.

## Install

### Shell (curl)

```sh
curl -fsSL https://raw.githubusercontent.com/teafey/swarm.skill/main/install.sh | bash
```

### NPX (from GitHub)

```sh
npx --yes -p github:teafey/swarm.skill swarm-skill-install
```

Both installers auto-detect agent directories and present an interactive menu:

```
  Swarm Skill Installer

  SPACE toggle  ↑↓ move  ENTER confirm  q quit

  ❯ [✔] Claude Code  ~/.claude/skills/swarm
    [✔] Codex         ~/.codex/skills/swarm
```

Toggle targets with **SPACE**, navigate with **arrow keys**, press **ENTER** to install.

### Options

| Flag | Description |
|------|-------------|
| `--yes`, `-y` | Skip menu, install to all detected agents |
| `--force`, `-f` | Overwrite existing installations |
| `--dir <path>` | Add a custom skills directory |
| `-h`, `--help` | Show help |

### Environment variables (shell installer)

| Variable | Description |
|----------|-------------|
| `CODEX_HOME` | Override Codex home directory |
| `REPO_OWNER` | GitHub repo owner (default: `teafey`) |
| `REPO_NAME` | GitHub repo name (default: `swarm.skill`) |
| `BRANCH` | Git branch (default: `main`) |

### Examples

```sh
# Non-interactive install to all detected agents
curl -fsSL .../install.sh | bash -s -- --yes

# Overwrite existing installations
npx --yes -p github:teafey/swarm.skill swarm-skill-install --force

# Install to a custom directory
npx --yes -p github:teafey/swarm.skill swarm-skill-install --dir ~/.my-agent/skills
```

### Detected agents

The installer checks for these directories:

| Agent | Home directory | Skills target |
|-------|---------------|---------------|
| Claude Code | `~/.claude` | `~/.claude/skills/swarm` |
| Codex | `~/.codex` (or `$CODEX_HOME`) | `~/.codex/skills/swarm` |

Additional targets can be added with `--dir`.

## Usage

Trigger the skill in chat when you want parallel execution with a team:

```text
/swarm <task>
```

Model-specific launch:

```text
/swarm haiku <task>
/swarm sonnet <task>
/swarm opus <task>
```

Common examples:

```text
/swarm 1. Add auth middleware 2. Add tests 3. Update docs 4. Wire CI
/swarm plan.md
/swarm parallelize checkout flow refactor
```

Behavior:

1. Parses your request into tasks.
2. Splits work into exactly 4 scoped agents.
3. Runs plan approval before implementation.
4. Tracks progress and returns a final summary.

## Development

1. Edit `SKILL.md`.
2. Validate behavior with real prompts that trigger swarm mode.
3. Commit changes with clear scope.

## Publish

1. `git remote add origin git@github.com:teafey/swarm.skill.git`
2. `git add .`
3. `git commit -m "chore: update installers"`
4. `git push -u origin main`
