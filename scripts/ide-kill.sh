#!/usr/bin/env bash
# ide-kill — stop the running process in a tmux pane and return focus to the IDE
#
# Usage:
#   ide-kill [session:window.pane]
#
# If no target is given, defaults to the active pane in the current session.
# This script is called by Hammerspoon hotkeys (Cmd+Shift+K) but can also
# be run manually from within tmux.

TARGET="${1:-}"

if [[ -n "$TARGET" ]]; then
  tmux send-keys -t "$TARGET" C-c
else
  tmux send-keys C-c
fi
