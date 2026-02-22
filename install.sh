#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> terminal-ide installer"
echo "    Repo: $REPO_DIR"
echo ""

# ── 1. Homebrew ────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for Apple Silicon (if not already set)
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

echo "==> Installing packages from Brewfile..."
brew bundle --file="$REPO_DIR/Brewfile"

# ── 2. Symlink helper ──────────────────────────────────────────────────────────
symlink() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    rm "$dst"
    echo "  replaced symlink: $dst"
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.bak"
    echo "  backed up existing file: $dst → $dst.bak"
  fi

  ln -s "$src" "$dst"
  echo "  linked: $dst → $src"
}

echo ""
echo "==> Creating symlinks..."

# Tmux
symlink "$REPO_DIR/config/tmux/tmux.conf"             "$HOME/.config/tmux/tmux.conf"

# Neovim (link the entire nvim directory)
symlink "$REPO_DIR/config/nvim"                        "$HOME/.config/nvim"

# WezTerm
symlink "$REPO_DIR/config/wezterm/wezterm.lua"         "$HOME/.wezterm.lua"

# Hammerspoon
symlink "$REPO_DIR/config/hammerspoon/init.lua"        "$HOME/.hammerspoon/init.lua"

# Yazi
symlink "$REPO_DIR/config/yazi/yazi.toml"             "$HOME/.config/yazi/yazi.toml"
symlink "$REPO_DIR/config/yazi/keymap.toml"           "$HOME/.config/yazi/keymap.toml"

# Tmuxinator
symlink "$REPO_DIR/config/tmuxinator"                  "$HOME/.config/tmuxinator"

# Scripts — add to ~/.local/bin so they're on PATH
mkdir -p "$HOME/.local/bin"
symlink "$REPO_DIR/scripts/ide-open.sh"                "$HOME/.local/bin/ide-open"
symlink "$REPO_DIR/scripts/ide-kill.sh"                "$HOME/.local/bin/ide-kill"

# ── 3. Tmux Plugin Manager (TPM) ──────────────────────────────────────────────
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo ""
  echo "==> Installing Tmux Plugin Manager..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# ── 4. Shell PATH ──────────────────────────────────────────────────────────────
# Ensure ~/.local/bin is on PATH. Add to .zshrc if not already present.
ZSHRC="$HOME/.zshrc"
if ! grep -q '\.local/bin' "$ZSHRC" 2>/dev/null; then
  echo ""
  echo "==> Adding ~/.local/bin to PATH in ~/.zshrc..."
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
fi

# ── 5. Done ────────────────────────────────────────────────────────────────────
echo ""
echo "==> Done."
echo ""
echo "Next steps:"
echo "  1. Open WezTerm — tmux will start automatically"
echo "  2. Inside tmux, run: nvim"
echo "     lazy.nvim will bootstrap and install plugins on first launch"
echo "  3. Inside tmux, press prefix + I to install tmux plugins (TPM)"
echo "  4. Open Hammerspoon and click 'Reload Config'"
echo "  5. Adjust config/hammerspoon/init.lua with your project's app names"
