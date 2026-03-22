# Changelog

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
