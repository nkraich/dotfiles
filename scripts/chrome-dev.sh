#!/usr/bin/env bash
# chrome-dev — launch a sandboxed Chrome instance for web dev testing
#
# Usage:
#   chrome-dev [URL] [--port PORT] [--name NAME]
#
# Examples:
#   chrome-dev http://localhost:3000
#   chrome-dev http://localhost:5173 --port 5173 --name "My App"
#
# What it does:
#   1. Creates a temporary .app bundle named after --name (default: "Chrome Dev")
#      so the dock and menu bar show your app name instead of "Google Chrome".
#   2. Launches Chrome inside the bundle with an isolated profile, DevTools open,
#      and the DevTools Protocol enabled on port 9222 for nvim-dap.
#   3. On exit: removes the temp bundle/profile and (if --port was given) kills
#      the process listening on that port (i.e. your dev server).

# ── Config ─────────────────────────────────────────────────────────────────────
CDP_PORT=9222
WINDOW_SIZE="1600,1000"

# ── Locate Chrome binary ───────────────────────────────────────────────────────
CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CHROME_CANARY="/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"

if [[ ! -x "$CHROME_BIN" ]]; then
  if [[ -x "$CHROME_CANARY" ]]; then
    CHROME_BIN="$CHROME_CANARY"
    echo "Note: using Chrome Canary"
  else
    echo "Error: Google Chrome not found." >&2
    echo "  Expected: $CHROME_BIN" >&2
    echo "  Install:  brew install --cask google-chrome" >&2
    exit 1
  fi
fi

# ── Parse arguments ────────────────────────────────────────────────────────────
URL=""
DEV_PORT=""
APP_NAME="Chrome Dev"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port)
      if [[ -z "$2" || "$2" == --* ]]; then
        echo "Error: --port requires a port number" >&2
        exit 1
      fi
      DEV_PORT="$2"
      shift 2
      ;;
    --port=*)
      DEV_PORT="${1#--port=}"
      shift
      ;;
    --name)
      if [[ -z "$2" || "$2" == --* ]]; then
        echo "Error: --name requires a value" >&2
        exit 1
      fi
      APP_NAME="$2"
      shift 2
      ;;
    --name=*)
      APP_NAME="${1#--name=}"
      shift
      ;;
    --*)
      echo "Error: unknown flag: $1" >&2
      echo "Usage: chrome-dev [URL] [--port PORT] [--name NAME]" >&2
      exit 1
      ;;
    *)
      if [[ -n "$URL" ]]; then
        echo "Error: unexpected argument: $1" >&2
        echo "Usage: chrome-dev [URL] [--port PORT] [--name NAME]" >&2
        exit 1
      fi
      URL="$1"
      shift
      ;;
  esac
done

if [[ -n "$DEV_PORT" ]] && ! [[ "$DEV_PORT" =~ ^[0-9]+$ ]]; then
  echo "Error: --port must be a number, got: $DEV_PORT" >&2
  exit 1
fi

# ── Create temp dirs ───────────────────────────────────────────────────────────
PROFILE_DIR="$(mktemp -d)"
BUNDLE_BASE="$(mktemp -d)"

# Pre-populate profile: disable "Warn Before Quitting" (Hold Cmd+Q prompt).
# This setting lives in Local State (user-data-dir root), not Default/Preferences.
printf '{"browser":{"confirm_to_quit":false}}' > "${PROFILE_DIR}/Local State"

# Sanitise name for filesystem and bundle ID (replace anything non-alphanum with -)
SAFE_NAME="${APP_NAME//[^a-zA-Z0-9._-]/-}"
APP_BUNDLE="${BUNDLE_BASE}/${APP_NAME}.app"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"

# ── Write Info.plist ───────────────────────────────────────────────────────────
cat > "${APP_BUNDLE}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleExecutable</key>
  <string>launcher</string>
  <key>CFBundleIdentifier</key>
  <string>com.chrome-dev.${SAFE_NAME}</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
</dict>
</plist>
PLIST

# ── Write launcher (values baked in at script runtime) ─────────────────────────
# Using exec replaces the launcher process with Chrome, so the bundle's process
# IS Chrome. open --wait-apps blocks until that process exits.
URL_ARG=""
[[ -n "$URL" ]] && URL_ARG="\"${URL}\""

cat > "${APP_BUNDLE}/Contents/MacOS/launcher" << LAUNCHER
#!/bin/bash
exec "${CHROME_BIN}" \\
  --user-data-dir="${PROFILE_DIR}" \\
  --remote-debugging-port="${CDP_PORT}" \\
  --auto-open-devtools-for-tabs \\
  --window-size="${WINDOW_SIZE}" \\
  --no-first-run \\
  --no-default-browser-check \\
  --disable-default-apps \\
  --disable-sync \\
  --disable-features=WarnBeforeClosing \\
  ${URL_ARG}
LAUNCHER
chmod +x "${APP_BUNDLE}/Contents/MacOS/launcher"

# ── Cleanup on exit ────────────────────────────────────────────────────────────
cleanup() {
  echo ""
  echo "==> ${APP_NAME}: cleaning up..."

  rm -rf "$PROFILE_DIR" "$BUNDLE_BASE"
  echo "  removed profile and app bundle"

  if [[ -n "$DEV_PORT" ]]; then
    local PIDS
    PIDS="$(lsof -ti :"$DEV_PORT" 2>/dev/null)"
    if [[ -n "$PIDS" ]]; then
      echo "  killing server on port $DEV_PORT (PID: $PIDS)"
      kill $PIDS 2>/dev/null || true
    else
      echo "  no process on port $DEV_PORT (already stopped)"
    fi
  fi
}

trap cleanup EXIT

# ── Launch ─────────────────────────────────────────────────────────────────────
echo "==> Launching ${APP_NAME}"
echo "  CDP port: $CDP_PORT (attach nvim-dap with <leader>dc)"
[[ -n "$URL" ]]      && echo "  URL:      $URL"
[[ -n "$DEV_PORT" ]] && echo "  On exit:  kill server on port $DEV_PORT"
echo ""

# open --wait-apps blocks until the app bundle exits
open --wait-apps "$APP_BUNDLE"

exit 0
