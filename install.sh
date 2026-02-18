#!/usr/bin/env sh
set -eu

REPO_OWNER="${REPO_OWNER:-teafey}"
REPO_NAME="${REPO_NAME:-swarm.skill}"
BRANCH="${BRANCH:-main}"
FORCE="${FORCE:-0}"

TARGET_ROOT="${TARGET_ROOT:-${CODEX_HOME:-$HOME/.codex}/skills}"
TARGET_DIR="$TARGET_ROOT/swarm"

if [ -e "$TARGET_DIR" ] && [ "$FORCE" != "1" ]; then
  echo "Target already exists: $TARGET_DIR"
  echo "Run with FORCE=1 to overwrite."
  exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

ARCHIVE_URL="https://codeload.github.com/$REPO_OWNER/$REPO_NAME/tar.gz/refs/heads/$BRANCH"
ARCHIVE_PATH="$TMP_DIR/repo.tar.gz"

curl -fsSL "$ARCHIVE_URL" -o "$ARCHIVE_PATH"
tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR"

SRC_DIR="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d -name "$REPO_NAME-*" | head -n 1)"

if [ -z "$SRC_DIR" ]; then
  echo "Could not locate extracted repository directory."
  exit 1
fi

mkdir -p "$TARGET_ROOT"

if [ -e "$TARGET_DIR" ]; then
  rm -rf "$TARGET_DIR"
fi

cp -R "$SRC_DIR" "$TARGET_DIR"
rm -rf "$TARGET_DIR/.git"

echo "Installed swarm skill to: $TARGET_DIR"
