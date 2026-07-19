#!/usr/bin/env bash
# ide-delete — remove a project directory (and its .ide.yml)
#
# Usage:
#   ide-delete <project-name>

set -e

PROJECTS_DIR="$HOME/Projects"

if [[ -z "$1" ]]; then
  echo "Usage: ide-delete <project-name>"
  exit 1
fi

NAME="$1"
PROJECT_DIR="$PROJECTS_DIR/$NAME"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Error: no project directory found: $PROJECT_DIR"
  exit 1
fi

# ── Confirm ───────────────────────────────────────────────────────────────────
echo "This will permanently delete:"
echo "  $PROJECT_DIR"
echo ""
read -r -p "Type the project name to confirm: " CONFIRM

if [[ "$CONFIRM" != "$NAME" ]]; then
  echo "Aborted."
  exit 1
fi

# ── Kill session if running ───────────────────────────────────────────────────
if tmux has-session -t "$NAME" 2>/dev/null; then
  tmux kill-session -t "$NAME"
  echo "Killed session: $NAME"
fi

rm -rf "$PROJECT_DIR"
echo "Deleted: $PROJECT_DIR"
