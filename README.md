# Swarm Skill

`swarm` is a Codex/Claude skill for team-based parallel execution.
It is based on Anthropic Agent Teams documentation: https://code.claude.com/docs/en/agent-teams

## What it does

- Triggers when users ask to run work with a team or in parallel.
- Splits work into 4 scoped agents.
- Enforces plan-first execution and file-scope isolation.
- Requires explicit review, progress tracking, and clean shutdown.

## Repository structure

- `SKILL.md` - full skill instructions and workflow.
- `README.md` - project overview.
- `LICENSE` - MIT license.
- `install.sh` - one-command shell installer.
- `scripts/install.js` - Node.js installer (for `npx`).
- `package.json` - npm metadata and CLI entrypoint.

## Quick install

Shell installer:

```sh
curl -fsSL https://raw.githubusercontent.com/teafey/swarm.skill/main/install.sh | sh
```

NPX installer (from GitHub):

```sh
npx --yes -p github:teafey/swarm.skill swarm-skill-install
```

By default, skill files are installed to `${CODEX_HOME:-$HOME/.codex}/skills/swarm`.

## Local usage

Place this folder in your skills directory and ensure the agent runtime can load `SKILL.md`.

## Development

1. Edit `SKILL.md`.
2. Validate behavior with real prompts that trigger swarm mode.
3. Commit changes with clear scope.

## Publish

1. `git remote add origin git@github.com:teafey/swarm.skill.git`
2. `git add .`
3. `git commit -m "chore: bootstrap swarm skill repo"`
4. `git push -u origin main`
