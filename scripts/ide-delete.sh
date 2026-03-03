#!/usr/bin/env bash
# ide-delete — remove a project's tmuxinator config and project directory
#
# Usage:
#   ide-delete <project-name>

set -e

TMUXINATOR_DIR="$HOME/.config/tmuxinator"
PROJECTS_DIR="$HOME/Projects"

# ── Validate arguments ────────────────────────────────────────────────────────
if [[ -z "$1" ]]; then
  echo "Usage: ide-delete <project-name>"
  exit 1
fi

NAME="$1"
CONFIG="$TMUXINATOR_DIR/${NAME}.yml"
PROJECT_DIR="$PROJECTS_DIR/${NAME}"

if [[ ! -f "$CONFIG" && ! -d "$PROJECT_DIR" ]]; then
  echo "Error: no tmuxinator config or project directory found for '${NAME}'"
  exit 1
fi

# ── Confirm ───────────────────────────────────────────────────────────────────
echo "This will permanently delete:"
[[ -f "$CONFIG" ]]     && echo "  $CONFIG"
[[ -d "$PROJECT_DIR" ]] && echo "  $PROJECT_DIR"
echo ""
read -r -p "Type the project name to confirm: " CONFIRM

if [[ "$CONFIRM" != "$NAME" ]]; then
  echo "Aborted."
  exit 1
fi

# ── Delete ────────────────────────────────────────────────────────────────────
if [[ -f "$CONFIG" ]]; then
  rm "$CONFIG"
  echo "Deleted: $CONFIG"
fi

if [[ -d "$PROJECT_DIR" ]]; then
  rm -rf "$PROJECT_DIR"
  echo "Deleted: $PROJECT_DIR"
fi
