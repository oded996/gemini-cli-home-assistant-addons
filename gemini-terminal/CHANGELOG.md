# Changelog

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
