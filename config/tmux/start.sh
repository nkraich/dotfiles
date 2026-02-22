#!/bin/zsh
# WezTerm startup script — attach to the last tmuxinator session, or fall back to 'main'.
export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
LAST="${HOME}/.local/share/tmux/last-session"
PROJECTS="${HOME}/.config/tmuxinator"

SESSION=""
[[ -f "$LAST" ]] && SESSION=$(<"$LAST")

if [[ -n "$SESSION" && -f "${PROJECTS}/${SESSION}.yml" ]]; then
  exec /opt/homebrew/bin/tmuxinator start "$SESSION"
fi

exec /opt/homebrew/bin/tmux new-session -A -s main
