-- ~/.hammerspoon/init.lua
-- terminal-ide global hotkeys

-- ── Config ─────────────────────────────────────────────────────────────────────
local TERMINAL_APP      = "WezTerm"
local BROWSER_APP       = "Google Chrome"
local YQ                = "/opt/homebrew/bin/yq"
local TMUX              = "/opt/homebrew/bin/tmux"
local PROJECTS_DIR      = os.getenv("HOME") .. "/Projects"
local LAST_SESSION_FILE = os.getenv("HOME") .. "/.local/share/tmux/last-session"
local LAST_PANE_FILE    = os.getenv("HOME") .. "/.local/share/tmux/last-command-pane"
local LAST_CMD_FILE     = os.getenv("HOME") .. "/.local/share/tmux/last-command"

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

local function readFile(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("*l")
  f:close()
  return s and s:match("^%s*(.-)%s*$")
end

local function writeFile(path, content)
  local f = io.open(path, "w")
  if f then f:write(content) f:close() end
end

local function currentProject()
  return readFile(LAST_SESSION_FILE)
end

local function yqGet(configPath, query)
  local f = io.popen(string.format("%s '%s' '%s' 2>/dev/null", YQ, query, configPath))
  if not f then return nil end
  local result = f:read("*l")
  f:close()
  if result == nil or result == "null" or result == "" then return nil end
  return result
end

local function tmuxSend(target, keys)
  os.execute(string.format("%s send-keys -t '%s' '%s' Enter",
    TMUX,
    target:gsub("'", "'\\''"),
    keys:gsub("'", "'\\''")
  ))
end

local function windowExists(session, windowName)
  local f = io.popen(string.format(
    "%s list-windows -t '%s' -F '#W' 2>/dev/null | grep -cx '%s'",
    TMUX, session, windowName
  ))
  if not f then return false end
  local n = tonumber(f:read("*l") or "0")
  f:close()
  return n and n > 0
end

-- ── Project commands ───────────────────────────────────────────────────────────
local function runProjectCommand(cmdName)
  local project = currentProject()
  if not project then
    hs.notify.new({ title = "terminal-ide", informativeText = "No active tmux session" }):send()
    return
  end

  local configPath = PROJECTS_DIR .. "/" .. project .. "/.ide.yml"
  local cmd  = yqGet(configPath, ".commands." .. cmdName .. ".cmd")
  local pane = yqGet(configPath, ".commands." .. cmdName .. ".pane")

  if not cmd then
    hs.notify.new({
      title           = "terminal-ide",
      informativeText = "No '" .. cmdName .. "' command in " .. project .. "/.ide.yml",
    }):send()
    return
  end

  local target
  if pane then
    target = project .. ":" .. pane
    os.execute(string.format("%s send-keys -t '%s' C-c", TMUX, target))
  else
    if windowExists(project, cmdName) then
      target = project .. ":" .. cmdName .. ".1"
      os.execute(string.format("%s send-keys -t '%s' C-c", TMUX, target))
    else
      os.execute(string.format("%s new-window -t '%s' -n '%s'", TMUX, project, cmdName))
      target = project .. ":" .. cmdName .. ".1"
    end
  end

  writeFile(LAST_PANE_FILE, target)
  writeFile(LAST_CMD_FILE, project .. ":" .. cmdName)

  hs.timer.doAfter(0.3, function()
    tmuxSend(target, cmd)
    focusApp(TERMINAL_APP)
  end)
end

local function killCommandPane()
  local lastCmd = readFile(LAST_CMD_FILE)
  local target  = readFile(LAST_PANE_FILE)

  if not target then
    hs.notify.new({ title = "terminal-ide", informativeText = "No command pane to kill" }):send()
    return
  end

  -- Check for a custom kill command in the yml
  local killCmd = nil
  if lastCmd then
    local project, cmdName = lastCmd:match("^(.+):(.+)$")
    if project and cmdName then
      local configPath = PROJECTS_DIR .. "/" .. project .. "/.ide.yml"
      killCmd = yqGet(configPath, ".commands." .. cmdName .. ".kill")
    end
  end

  if killCmd then
    os.execute(killCmd)
  else
    os.execute(string.format("%s send-keys -t '%s' C-c", TMUX, target))
  end

  focusApp(TERMINAL_APP)
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

-- Cmd+Shift+E → focus the editor window in the current project
hs.hotkey.bind({ "cmd", "shift" }, "E", function()
  local project = currentProject() or "main"
  os.execute(string.format("%s select-window -t '%s:editor'", TMUX, project))
  focusApp(TERMINAL_APP)
end)

-- ── Project command shortcuts ───────────────────────────────────────────────────
-- Cmd+Shift+R → run
hs.hotkey.bind({ "cmd", "shift" }, "R", function() runProjectCommand("run")   end)

-- Cmd+Shift+B → build
hs.hotkey.bind({ "cmd", "shift" }, "B", function() runProjectCommand("build") end)

-- Cmd+Shift+C → clean
hs.hotkey.bind({ "cmd", "shift" }, "C", function() runProjectCommand("clean") end)

-- Cmd+Shift+K → kill the last command
hs.hotkey.bind({ "cmd", "shift" }, "K", function() killCommandPane() end)

-- ── Reload Hammerspoon config ──────────────────────────────────────────────────
hs.hotkey.bind({ "cmd", "shift" }, "0", function()
  hs.reload()
end)

hs.notify.new({ title = "terminal-ide", informativeText = "Hammerspoon config loaded" }):send()
