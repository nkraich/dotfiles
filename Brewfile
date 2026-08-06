# Brewfile — terminal-ide dependencies
# Install everything: brew bundle install
# Regenerate from current machine: brew bundle dump --force

# ── CLI tools ──────────────────────────────────────────────────────────────────
brew "tmux"
brew "neovim"
brew "yazi"           # terminal file browser
brew "nvr"            # neovim-remote: open files in running nvim instance
brew "tmuxinator"     # tmux session templates
brew "yq"             # YAML query tool (used by Hammerspoon to read .ide.yml commands)
brew "direnv"         # per-project environment variables
brew "mise"           # per-project language runtime versions (node, python, ruby, etc.)

# Neovim dependencies
brew "ripgrep"        # fast grep (used by telescope.nvim)
brew "fd"             # fast find (used by telescope.nvim and yazi)
brew "lazygit"        # git TUI (optional, integrates with nvim)

# Yazi optional dependencies (previews)
brew "ffmpegthumbnailer"  # video thumbnails
brew "imagemagick"         # image previews
brew "poppler"             # PDF previews

# ── GUI apps ───────────────────────────────────────────────────────────────────
cask "wezterm"        # terminal emulator
cask "hammerspoon"    # macOS automation and global hotkeys
