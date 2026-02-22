-- ~/.hammerspoon/init.lua
-- terminal-ide global hotkeys
--
-- After editing this file, click "Reload Config" in the Hammerspoon menu bar icon,
-- or press Cmd+Shift+R if you have that binding set.

-- ── Config ─────────────────────────────────────────────────────────────────────
-- Set these to the app names as macOS knows them.
-- Find the right name: open the app, then run in Hammerspoon console:
--   hs.application.frontmostApplication():name()
local TERMINAL_APP = "WezTerm"
local BROWSER_APP  = "Google Chrome"  -- change to your debug target app name

-- tmux target for the debugger/server pane.
-- Format: session:window.pane  (use `tmux list-panes -a` to find yours)
-- tmuxinator templates in this repo use a named session per project;
-- update this when switching projects or set it dynamically via ide-open.sh.
local TMUX_DEBUGGER_PANE = "main:server.1"

-- ── Helpers ────────────────────────────────────────────────────────────────────
local function focusApp(name)
  local app = hs.application.get(name)
  if app then
    app:activate()
    local win = app:mainWindow()
    if win then win:focus() end
  else
    hs.notify.new({ title = "terminal-ide", informativeText = name .. " is not running" }):send()
  end
end

local function tmuxSendKeys(target, keys)
  local cmd = string.format("tmux send-keys -t '%s' %s", target, keys)
  os.execute(cmd)
end

-- ── Window focus ───────────────────────────────────────────────────────────────
-- Cmd+Shift+1 → focus WezTerm, or launch it if not running
hs.hotkey.bind({ "cmd", "shift" }, "1", function()
  hs.application.launchOrFocus(TERMINAL_APP)
end)

-- Cmd+Shift+2 → focus the debug target app
hs.hotkey.bind({ "cmd", "shift" }, "2", function()
  focusApp(BROWSER_APP)
end)

-- ── Debugger control ───────────────────────────────────────────────────────────
-- Cmd+Shift+B → send Ctrl-C to the debugger pane (break / interrupt)
hs.hotkey.bind({ "cmd", "shift" }, "B", function()
  tmuxSendKeys(TMUX_DEBUGGER_PANE, "C-c")
  focusApp(TERMINAL_APP)
end)

-- Cmd+Shift+K → kill the process in the debugger pane and return to IDE
hs.hotkey.bind({ "cmd", "shift" }, "K", function()
  tmuxSendKeys(TMUX_DEBUGGER_PANE, "C-c")
  focusApp(TERMINAL_APP)
end)

-- Cmd+Shift+R → restart the process in the debugger pane
-- (sends Ctrl-C then runs the last command)
hs.hotkey.bind({ "cmd", "shift" }, "R", function()
  tmuxSendKeys(TMUX_DEBUGGER_PANE, "C-c")
  -- Small delay to let the process die before restarting
  hs.timer.doAfter(0.3, function()
    tmuxSendKeys(TMUX_DEBUGGER_PANE, "Up Enter")
  end)
end)

-- ── Neovim remote commands ─────────────────────────────────────────────────────
-- Cmd+Shift+E → jump to the editor pane in tmux and enter neovim command mode
hs.hotkey.bind({ "cmd", "shift" }, "E", function()
  -- Switch to the editor window in tmux, then focus the terminal
  os.execute("tmux select-window -t main:editor")
  focusApp(TERMINAL_APP)
end)

-- ── Reload Hammerspoon config ──────────────────────────────────────────────────
hs.hotkey.bind({ "cmd", "shift" }, "0", function()
  hs.reload()
end)

hs.notify.new({ title = "terminal-ide", informativeText = "Hammerspoon config loaded" }):send()
