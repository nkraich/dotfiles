#!/usr/bin/env bash
# ide-new — scaffold a new project directory and tmuxinator config
#
# Usage:
#   ide-new <project-name>
#
# The script:
#   1. Creates ~/Projects/<name>/
#   2. Clones ~/.config/tmuxinator/example.yml → <name>.yml
#      with name, root, and socket path updated automatically

set -e

TMUXINATOR_DIR="$HOME/.config/tmuxinator"
PROJECTS_DIR="$HOME/Projects"
EXAMPLE="$TMUXINATOR_DIR/example.yml"

# ── Validate arguments ────────────────────────────────────────────────────────
if [[ -z "$1" ]]; then
  echo "Usage: ide-new <project-name>"
  exit 1
fi

NAME="$1"
CONFIG="$TMUXINATOR_DIR/${NAME}.yml"
PROJECT_DIR="$PROJECTS_DIR/${NAME}"

if [[ ! -f "$EXAMPLE" ]]; then
  echo "Error: example config not found at $EXAMPLE"
  exit 1
fi

if [[ -f "$CONFIG" ]]; then
  echo "Error: tmuxinator config already exists: $CONFIG"
  exit 1
fi

# ── Create project directory ──────────────────────────────────────────────────
if [[ -d "$PROJECT_DIR" ]]; then
  echo "Directory already exists: $PROJECT_DIR"
else
  mkdir -p "$PROJECT_DIR"
  echo "Created: $PROJECT_DIR"
fi

# ── Clone and patch example config ───────────────────────────────────────────
sed \
  -e "s|^name:.*|name: ${NAME}|" \
  -e "s|^root:.*|root: ~/Projects/${NAME}|" \
  -e "s|/tmp/nvim-example\.sock|/tmp/nvim-${NAME}.sock|g" \
  "$EXAMPLE" > "$CONFIG"

echo "Created: $CONFIG"
echo ""
tmuxinator start "$NAME"
