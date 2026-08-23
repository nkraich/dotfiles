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
symlink "$REPO_DIR/config/tmux/start.sh"              "$HOME/.config/tmux/start.sh"
chmod +x "$REPO_DIR/config/tmux/start.sh"

# Neovim (link the entire nvim directory)
symlink "$REPO_DIR/config/nvim"                        "$HOME/.config/nvim"

# WezTerm
symlink "$REPO_DIR/config/wezterm/wezterm.lua"         "$HOME/.wezterm.lua"

# Hammerspoon
symlink "$REPO_DIR/config/hammerspoon/init.lua"        "$HOME/.hammerspoon/init.lua"

# Yazi
symlink "$REPO_DIR/config/yazi/yazi.toml"             "$HOME/.config/yazi/yazi.toml"
symlink "$REPO_DIR/config/yazi/keymap.toml"           "$HOME/.config/yazi/keymap.toml"
symlink "$REPO_DIR/config/yazi/init.lua"              "$HOME/.config/yazi/init.lua"
symlink "$REPO_DIR/config/yazi/package.toml"          "$HOME/.config/yazi/package.toml"

# Tmuxinator
symlink "$REPO_DIR/config/tmuxinator"                  "$HOME/.config/tmuxinator"

# Scripts — add to ~/.local/bin so they're on PATH
mkdir -p "$HOME/.local/bin"
symlink "$REPO_DIR/scripts/ide-open.sh"                "$HOME/.local/bin/ide-open"
symlink "$REPO_DIR/scripts/ide-kill.sh"                "$HOME/.local/bin/ide-kill"
symlink "$REPO_DIR/scripts/ide-new.sh"                 "$HOME/.local/bin/ide-new"
symlink "$REPO_DIR/scripts/ide-delete.sh"              "$HOME/.local/bin/ide-delete"
symlink "$REPO_DIR/scripts/chrome-dev.sh"             "$HOME/.local/bin/chrome-dev"
chmod +x "$REPO_DIR/scripts/chrome-dev.sh"

# ── 3. Yazi packages ───────────────────────────────────────────────────────────
echo ""
echo "==> Installing Yazi packages..."
ya pkg install

# ── 4. Tmux Plugin Manager (TPM) ──────────────────────────────────────────────
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo ""
  echo "==> Installing Tmux Plugin Manager..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# ── 5. Shell PATH ──────────────────────────────────────────────────────────────
# Ensure ~/.local/bin is on PATH. Add to .zshrc if not already present.
ZSHRC="$HOME/.zshrc"
if ! grep -q '\.local/bin' "$ZSHRC" 2>/dev/null; then
  echo ""
  echo "==> Adding ~/.local/bin to PATH in ~/.zshrc..."
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
fi

# mise (per-project language runtime versions). Activate its shims in the
# shell and install a global Node so tools that spawn outside any project
# directory (e.g. Mason in nvim) still find node/npm.
if ! grep -q 'mise activate' "$ZSHRC" 2>/dev/null; then
  echo ""
  echo "==> Adding 'mise activate' to ~/.zshrc..."
  echo 'eval "$(mise activate zsh)"' >> "$ZSHRC"
fi

echo ""
echo "==> Installing global Node via mise..."
mise use --global node@lts

# ── 6. Sanity checks ───────────────────────────────────────────────────────────
# Catch broken configs / missing tools now instead of the next time the
# affected tool is opened.
echo ""
echo "==> Running sanity checks..."

if ! yazi --version &>/dev/null; then
  echo "  WARNING: 'yazi --version' failed — yazi.toml likely has a config error. Run 'yazi --version' to see it."
fi

if ! zsh -ic 'command -v npm' &>/dev/null; then
  echo "  WARNING: npm is not resolving in an interactive shell — check mise activation in ~/.zshrc."
fi

# ── 7. Done ────────────────────────────────────────────────────────────────────
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
