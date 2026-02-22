local wezterm = require 'wezterm'
local config  = wezterm.config_builder()

-- ── Font ───────────────────────────────────────────────────────────────────────
config.font      = wezterm.font('JetBrains Mono', { weight = 'Regular' })
config.font_size = 13.0

-- ── Colors ─────────────────────────────────────────────────────────────────────
config.color_scheme = 'Catppuccin Mocha'

-- ── Window chrome ──────────────────────────────────────────────────────────────
-- RESIZE-only decorations: keeps the native resize border but hides the title bar.
-- This gives a cleaner look while still allowing window resizing.
config.window_decorations    = "RESIZE"
config.window_padding        = { left = 4, right = 4, top = 4, bottom = 4 }
config.hide_tab_bar_if_only_one_tab = true

-- ── Startup: maximize window and attach to (or create) main tmux session ───────
config.default_prog = { '/opt/homebrew/bin/tmux', 'new-session', '-A', '-s', 'main' }

wezterm.on('gui-startup', function(cmd)
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

-- ── Scrollback ─────────────────────────────────────────────────────────────────
-- tmux manages scrollback; keep WezTerm's minimal
config.scrollback_lines = 1000

-- ── Key bindings ───────────────────────────────────────────────────────────────
-- Disable WezTerm's own tab/pane shortcuts so they don't conflict with tmux
config.keys = {
  -- Paste from clipboard
  { key = 'v', mods = 'CMD',        action = wezterm.action.PasteFrom 'Clipboard' },
  -- Copy selected text
  { key = 'c', mods = 'CMD',        action = wezterm.action.CopyTo 'Clipboard' },
  -- Increase/decrease font size
  { key = '=', mods = 'CMD',        action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CMD',        action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CMD',        action = wezterm.action.ResetFontSize },
}

return config
