# Changelog

## 2.0.5
- **🔍 Improved Log Visibility**
  - Implemented real-time log streaming from Gemini internal logs to the Home Assistant "Logs" tab.
  - Internal Gemini events will now appear with a `[Gemini-Internal]` prefix.


## 2.0.4
- **🛠️ Log Mirroring & Boot Fix**
  - Reverted direct log writing to fix boot failures.
  - Implemented background log mirroring to `/config/gemini-logs` for safe, read-only access.
  - Kept 4GB RAM unlock and disabled sandbox for maximum stability.


## 2.0.3
- **🛠️ Log Access & Stability Fix**
  - Changed internal log path to a real folder (`/config/gemini-logs`) to fix "Access Denied" errors in File Editor.
  - Explicitly disabled Gemini sandbox (`--sandbox false`) for better container compatibility.


## 2.0.2
- **⚙️ Memory & Diagnostics Fix**
  - Increased RAM limit to 4GB and CPU to 4.0.
  - Explicitly allocated 4GB to Node.js heap to prevent OOM crashes on complex tasks.
  - Created `/config/gemini-logs` symlink for easier access to internal logs.
  - Added `/config/gemini_system.log` to track resource limits.


## 2.0.1
- **🛡️ Timeout & Performance Fix**
  - Reduced ttyd ping-interval to 5s to prevent Home Assistant Ingress timeouts during long tasks.
  - Added default `.geminiignore` to skip large database files, improving directory scan speed.


## 2.0.7
- **⚡ Interface Stability Fix**
  - Disabled experimental background tasks (`--experimental-acp false`) that caused terminal corruption and crashes during large outputs.
  - Forced stable interactive mode to prevent V8 engine assertion failures.


## 2.2.3
- **🛡️ Strict Isolation Fix**
  - Permanently removed `gemini-logs` from the config directory to break recursive crash loops.
  - Switched terminal renderer to `canvas` to improve text selection/copy support in browser iframes.
  - Added `GEMINI_MAX_FILE_SIZE_BYTES` limit to prevent memory exhaustion on large files.


## 2.2.2
- **🛠️ Fixed Startup & Clipboard**
  - Fixed "stack-size not allowed" error by passing the flag directly to the Node binary.
  - Forced clipboard support with `enableClipboard=true` to fix copy issues.
  - Improved background launch reliability.


## 2.3.0
- **🛠️ Interactivity & Config Fix**
  - Fixed "No input provided via stdin" by switching to passive tmux logging.
  - Fixed invalid `settings.json` format causing startup errors.
  - Maintains full crash diagnostics in `/config/gemini_crash.log` without breaking the TTY.


## 2.2.9
- **🛠️ Fix Startup Error**
  - Removed invalid `autocomplete` arguments that prevented Gemini from starting.
  - Updated deprecated `--experimental-acp` to `--acp`.


## 2.2.8
- **🔍 Definitve Diagnostic Update (The Witness)**
  - Implemented `gemini-witness` wrapper to capture all output and exit codes directly to `/config/gemini_crash.log`.
  - Added strict isolation rules to prevent Gemini from reading its own logs.
  - Enabled native Node.js crash reporting (`.json` reports in `/config`).
  - Improved browser copy support with `allowContextMenu=true`.


## 2.2.7
- **✨ UX & Native Experience Update**
  - Removed annoying "Screen Reader" mode while maintaining stability.
  - Fixed Copy/Paste: Disabled `tmux` mouse mode to allow native browser text selection.
  - Hard-disabled background "flickering" tasks (`--no-autocomplete`) to prevent TTY crashes.
  - Improved startup speed and UI feedback.


## 2.2.6
- **🛡️ Hardened Configuration Override**
  - Forcibly overwrites `settings.json` on every boot to ensure "YOLO" and "Screen Reader" modes are active.
  - This prevents Gemini from ignoring command line flags and showing unstable interactive popups.
  - Switched terminal renderer to `webgl` to improve copy/paste support.


## 2.2.5
- **🎨 UI Restoration & High Stability**
  - Restored full colors and the dark "Terracotta" theme.
  - Added `--screen-reader` mode: disables unstable background flickering while keeping full functionality.
  - Fixed copy/paste support and restored standard browser text selection.


## 2.2.4
- **🛠️ UI & Compatibility Fix**
  - Fixed "Approval Crash" by forcing `TERM=vt100` (Legacy Mode). This disables unstable mouse-UI popups.
  - Improved Copy/Paste support: reverted to high-contrast theme and added `Shift+Select` tip.
  - Aggressively cleaned startup logic to ensure a fresh session every boot.


## 2.2.1
- **🛠️ UI & Core Stability**
  - Fixed standard copy/paste support by enabling `copyOnSelect` and using a native theme.
  - Increased Node.js stack size to 10MB to prevent recursion crashes during directory scans.
  - Improved tmux attachment logic for better browser-to-container reliability.


## 2.3.1
- **🛠️ Ultra-Stable Mode**
  - Switched to `-y` flag for absolute YOLO mode to bypass all approval prompts.
  - Forced `TERM=linux` to disable unstable terminal UI features.
  - Added detection of existing crash reports in startup logs.


## 2.2.0
- **🛡️ Persistent Daemon Architecture**
  - Gemini now runs as a background service: survives browser refreshes and proxy timeouts.
  - Hidden Logs: Moved logs to `/config/.gemini_logs` so the AI doesn't scan itself and crash.
  - Forced `TERM=vt100` for the background session to prevent UI corruption.
  - Auto-Reconnect: Simply refresh your browser to re-attach to your active work.


## 2.1.0
- **🚀 Stability Mega-Fix**
  - Re-integrated critical stability flags discovered during 1.x testing into the stable 2.x foundation.
  - Added `FSWATCH_BACKEND=poll` to prevent file watcher crashes in the large Home Assistant `/config` directory.
  - Disabled unstable background features (`--experimental-acp false`) and output sanitization (`--raw-output`) to prevent engine panic.
  - Increased thread pool size for better performance during complex tasks.


## 2.0.6
- **🔍 Deep Screen Capture**
  - Implemented `tmux pipe-pane` to capture every character seen on the screen to `/config/gemini_screen.log`.
  - These "Screen Logs" are automatically streamed to the Home Assistant "Logs" tab for debugging.
  - This method is non-invasive and cannot cause blank screens or process hangs.


## 2.0.0
- **🚀 Stable Release Redux**
  - Reverted to the highly stable v1.1.5 foundation to eliminate persistent crashes.
  - Added `gemini_debug` setting to toggle the `--debug` flag.
  - Integrated internal Gemini logs into the Home Assistant Add-on logs for easier troubleshooting.

## 1.1.0

- **🛠️ Fixes**
  - Fixed "WebSocket not authenticated" error for Home Assistant MCP tools.
  - Upgraded add-on permissions to "admin" for full entity and dashboard control.
  - Added compatibility environment variables (HASS_TOKEN/HASS_URL) for the MCP server.


## 1.1.4
- **⚡ Performance & UX**
  - Removed the welcome screen entirely for a faster, cleaner startup.
  - Added a "Initializing Gemini Terminal..." indicator for better feedback during loading.


## 1.1.3
- **⚡ UX Improvements**
  - Removed the "Press Enter to continue" prompt on startup for faster access.
  - Updated welcome banner with correct version history.


## 1.1.2
- **📖 Documentation**
  - Added "Safety & Guardrails" section to clarify how Gemini handles file edits.
  - Documented "Plan Mode" (`--approval-mode plan`) for dry-runs.


## 1.1.1
- **🛠️ Fixes**
  - Added build dependencies (`build-base`, `g++`, `make`) to the Dockerfile. This fixes the installation error when compiling native npm modules like `tree-sitter-bash`.

## 1.1.0
- **🚀 First Stable Public Release**
  - **Pre-installed Home Assistant MCP Server**: Gemini Terminal now includes `ha-mcp` for robust, natural language control of entities.
  - **Enhanced Logging**: Integrated startup diagnostics and API key masking.
  - **Persistent Shell Support**: Terminal now remains open even if the main process exits.
  - **Full Gemini-CLI Integration**: Full support for Google's newest AI coding assistant.
  - **Port 7682**: Changed default port to avoid conflicts with other add-ons.

## 1.0.7
- **✨ New Features**
  - **Pre-installed Home Assistant MCP Server**: Gemini Terminal now includes `ha-mcp` pre-installed for better stability.
  - **Improved Startup**: Fixed MCP connection issues by using local `ha-mcp` binary instead of `uvx`.
  - **Enhanced Logging**: Added detailed startup diagnostics for easier troubleshooting.

## 1.0.6
- **🛠️ Fixes**
  - Corrected `gemini mcp add` command syntax for better compatibility.

## 1.0.5
- **🛠️ Fixes**
  - Improved API key recognition by exporting both `GOOGLE_API_KEY` and `GEMINI_API_KEY`.
  - Propagated API key through `tmux` sessions.

## 1.0.4
- **📦 Technical Details**
  - Installed `coreutils` to support the `-S` flag in `env`, fixing the "unrecognized option: S" error.

## 1.0.3
- **✨ New Features**
  - **Persistent Shell**: Terminal now drops to a `bash` shell if Gemini exits, preventing the terminal from closing.
  - **Restored uv**: Re-added `uv` package for MCP support.

## 1.0.0 - 1.0.2
- **🚀 Initial Release**
  - Forked from Claude Terminal and converted to use Google's Gemini CLI.
  - Renamed all components, scripts, and documentation to Gemini.
  - Added support for Gemini API key configuration via Home Assistant UI.
  - Integrated Home Assistant context (`GEMINI.md`) for AI awareness.
  - Bundled Home Assistant MCP Server for natural language control.
  - Configured web terminal on port 7682.
