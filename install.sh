#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="${REPO_OWNER:-teafey}"
REPO_NAME="${REPO_NAME:-swarm.skill}"
BRANCH="${BRANCH:-main}"
SKILL="swarm"

# ── Cleanup ────────────────────────────────────────────
_tmp=""
_cursor_hidden=0

cleanup() {
  [[ "$_cursor_hidden" -eq 1 ]] && printf '\033[?25h' 2>/dev/null || true
  [[ -n "$_tmp" ]] && rm -rf "$_tmp" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# ── Parse arguments ────────────────────────────────────
FORCE=0
YES=0
EXTRA_DIRS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force|-f) FORCE=1; shift ;;
    --yes|-y)   YES=1; shift ;;
    --dir)
      [[ $# -lt 2 ]] && { echo "Error: --dir requires a path"; exit 1; }
      EXTRA_DIRS+=("$2"); shift 2 ;;
    --dir=*) EXTRA_DIRS+=("${1#--dir=}"); shift ;;
    -h|--help)
      cat <<'EOF'
Swarm Skill Installer

Usage: install.sh [options]

Options:
  --yes, -y       Skip menu, install to all detected agents
  --force, -f     Overwrite existing installations
  --dir <path>    Add a custom skills directory
  -h, --help      Show this help

Environment:
  CODEX_HOME      Override Codex home directory
  REPO_OWNER      GitHub repo owner  (default: teafey)
  REPO_NAME       GitHub repo name   (default: swarm.skill)
  BRANCH          Git branch         (default: main)
EOF
      exit 0 ;;
    *) shift ;;
  esac
done

# ── Colors ─────────────────────────────────────────────
BOLD='' DIM='' GREEN='' CYAN='' YELLOW='' RED='' RESET=''
if [[ -t 1 ]] || [[ -e /dev/tty ]]; then
  BOLD=$'\033[1m'  DIM=$'\033[2m'
  GREEN=$'\033[32m' CYAN=$'\033[36m'
  YELLOW=$'\033[33m' RED=$'\033[31m'
  RESET=$'\033[0m'
fi

# ── Detect agents ──────────────────────────────────────
NAMES=()
PATHS=()
SELECTED=()

add_agent() {
  local name="$1" dir="$2"
  for p in "${PATHS[@]+"${PATHS[@]}"}"; do
    [[ "$p" == "$dir" ]] && return
  done
  NAMES+=("$name")
  PATHS+=("$dir")
  SELECTED+=(1)
}

[[ -d "$HOME/.claude" ]] && add_agent "Claude Code" "$HOME/.claude/skills"

_codex="${CODEX_HOME:-$HOME/.codex}"
[[ -d "$_codex" ]] && add_agent "Codex" "$_codex/skills"

for d in "${EXTRA_DIRS[@]+"${EXTRA_DIRS[@]}"}"; do
  add_agent "Custom ($d)" "$d"
done

if [[ ${#NAMES[@]} -eq 0 ]]; then
  printf '%s\n' "${RED}No agent directories detected.${RESET}"
  printf '%s\n' "Use ${BOLD}--dir <path>${RESET} to specify a skills directory."
  exit 1
fi

# ── Interactive menu ───────────────────────────────────
TTY=""
if [[ -t 0 ]]; then
  TTY=/dev/stdin
elif [[ -e /dev/tty ]]; then
  TTY=/dev/tty
fi

_menu_lines=0

draw_menu() {
  local cursor=$1
  local count=${#NAMES[@]}

  # erase previous draw
  if [[ $_menu_lines -gt 0 ]]; then
    local l
    for ((l = 0; l < _menu_lines; l++)); do
      printf '\033[A\033[2K'
    done
  fi

  _menu_lines=0

  printf '\n';                                                                           ((_menu_lines++))
  printf '  %s\n' "${BOLD}Swarm Skill Installer${RESET}";                               ((_menu_lines++))
  printf '\n';                                                                           ((_menu_lines++))
  printf '  %s\n' "${DIM}SPACE${RESET} toggle  ${DIM}↑↓${RESET} move  ${DIM}ENTER${RESET} confirm  ${DIM}q${RESET} quit"; ((_menu_lines++))
  printf '\n';                                                                           ((_menu_lines++))

  local i
  for ((i = 0; i < count; i++)); do
    local check=" "
    [[ "${SELECTED[$i]}" -eq 1 ]] && check="${GREEN}✔${RESET}"

    local ptr="  "
    [[ "$i" -eq "$cursor" ]] && ptr="${CYAN}❯${RESET} "

    local flag=""
    [[ -d "${PATHS[$i]}/$SKILL" ]] && flag="  ${YELLOW}(exists)${RESET}"

    printf '  %s[%s] %s  %s%s\n' \
      "$ptr" "$check" "${BOLD}${NAMES[$i]}${RESET}" \
      "${DIM}${PATHS[$i]}/$SKILL${RESET}" "$flag"
    ((_menu_lines++))
  done

  printf '\n'; ((_menu_lines++))
}

run_menu() {
  local cursor=0
  local count=${#NAMES[@]}

  printf '\033[?25l'  # hide cursor
  _cursor_hidden=1

  draw_menu "$cursor"

  while true; do
    IFS= read -rsn1 key <"$TTY"
    case "$key" in
      $'\x1b')
        read -rsn2 -t 0.1 seq <"$TTY" || true
        case "${seq:-}" in
          '[A') ((cursor > 0)) && ((cursor--)) || true ;;
          '[B') ((cursor < count - 1)) && ((cursor++)) || true ;;
        esac ;;
      ' ')
        if [[ "${SELECTED[$cursor]}" -eq 1 ]]; then
          SELECTED[$cursor]=0
        else
          SELECTED[$cursor]=1
        fi ;;
      ''|$'\n')
        break ;;
      q|$'\x03')
        printf '\033[?25h'
        _cursor_hidden=0
        printf '  Cancelled.\n'
        exit 0 ;;
    esac
    draw_menu "$cursor"
  done

  printf '\033[?25h'
  _cursor_hidden=0
}

if [[ "$YES" -eq 0 ]] && [[ -n "$TTY" ]]; then
  run_menu
fi

# ── Collect targets ────────────────────────────────────
TARGETS=()
for ((i = 0; i < ${#NAMES[@]}; i++)); do
  [[ "${SELECTED[$i]}" -eq 1 ]] && TARGETS+=("$i")
done

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  printf '  No targets selected.\n'
  exit 0
fi

# ── Download ───────────────────────────────────────────
_tmp="$(mktemp -d)"

ARCHIVE_URL="https://codeload.github.com/$REPO_OWNER/$REPO_NAME/tar.gz/refs/heads/$BRANCH"

printf '  %sDownloading %s/%s@%s…%s\n' "$DIM" "$REPO_OWNER" "$REPO_NAME" "$BRANCH" "$RESET"
curl -fsSL "$ARCHIVE_URL" -o "$_tmp/repo.tar.gz"
tar -xzf "$_tmp/repo.tar.gz" -C "$_tmp"

SRC_DIR="$(find "$_tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
if [[ -z "$SRC_DIR" ]]; then
  printf '  %sFailed to extract archive.%s\n' "$RED" "$RESET"
  exit 1
fi

# ── Install ────────────────────────────────────────────
printf '\n'
for idx in "${TARGETS[@]}"; do
  name="${NAMES[$idx]}"
  target="${PATHS[$idx]}/$SKILL"

  if [[ -d "$target" ]]; then
    if [[ "$FORCE" -eq 0 ]]; then
      printf '  %s⚠ %s: already exists (use --force)%s\n' "$YELLOW" "$name" "$RESET"
      continue
    fi
    rm -rf "$target"
  fi

  mkdir -p "${PATHS[$idx]}"
  cp -R "$SRC_DIR" "$target"
  rm -rf "$target/.git"
  printf '  %s✔%s %s%s%s  %s%s%s\n' \
    "$GREEN" "$RESET" "$BOLD" "$name" "$RESET" "$DIM" "$target" "$RESET"
done

printf '\n  %s%sDone!%s\n\n' "$GREEN" "$BOLD" "$RESET"
