#!/usr/bin/env bash
# ide-open — start or attach to a tmuxinator project session
#
# Usage:
#   ide-open <project-name>
#   ide-open              (lists available projects)
#
# The script:
#   1. Checks that a tmuxinator config exists for the project
#   2. Starts or attaches to the tmux session
#   3. Updates the Hammerspoon debugger pane target for this project

set -e

# ── List projects if no argument given ────────────────────────────────────────
if [[ -z "$1" ]]; then
  echo "Available projects:"
  tmuxinator list 2>/dev/null | tail -n +2
  echo ""
  echo "Usage: ide-open <project-name>"
  exit 0
fi

PROJECT="$1"
TMUXINATOR_CONFIG="$HOME/.config/tmuxinator/${PROJECT}.yml"

if [[ ! -f "$TMUXINATOR_CONFIG" ]]; then
  echo "Error: No tmuxinator config found at $TMUXINATOR_CONFIG"
  echo "Copy config/tmuxinator/example.yml and rename it to ${PROJECT}.yml"
  exit 1
fi

# ── Start or attach ───────────────────────────────────────────────────────────
if tmux has-session -t "$PROJECT" 2>/dev/null; then
  echo "Attaching to existing session: $PROJECT"
  tmux attach-session -t "$PROJECT"
else
  echo "Starting new session: $PROJECT"
  tmuxinator start "$PROJECT"
fi
