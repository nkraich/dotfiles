#!/usr/bin/env bash
# ide-open — open a project by name, creating its .ide.yml if needed
#
# Usage:
#   ide-open <project-name>   open ~/Projects/<project-name>
#   ide-open                  list available projects

set -e

PROJECTS_DIR="$HOME/Projects"
TEMPLATE="$HOME/.config/tmuxinator/template.yml"

# ── List projects if no argument given ───────────────────────────────────────
if [[ -z "$1" ]]; then
  echo "Available projects:"
  for d in "$PROJECTS_DIR"/*/; do
    name=$(basename "$d")
    if [[ -f "$d/.ide.yml" ]]; then
      echo "  $name"
    fi
  done
  echo ""
  echo "Usage: ide-open <project-name>"
  exit 0
fi

NAME="$1"
PROJECT_DIR="$PROJECTS_DIR/$NAME"
CONFIG="$PROJECT_DIR/.ide.yml"

if [[ ! -d "$PROJECT_DIR" ]]; then
  mkdir -p "$PROJECT_DIR"
  echo "Created: $PROJECT_DIR"
fi

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: template not found: $TEMPLATE"
  exit 1
fi

# ── Create .ide.yml from template if missing ─────────────────────────────────
if [[ ! -f "$CONFIG" ]]; then
  sed "s/PROJECT_NAME/$NAME/g" "$TEMPLATE" > "$CONFIG"
  echo "Created: $CONFIG"
fi

# ── Start or attach/switch ────────────────────────────────────────────────────
if tmux has-session -t "$NAME" 2>/dev/null; then
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$NAME"
  else
    tmux attach-session -t "$NAME"
  fi
else
  echo "Starting new session: $NAME"
  tmuxinator start "$NAME" --project-config="$CONFIG"
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$NAME"
  fi
fi
