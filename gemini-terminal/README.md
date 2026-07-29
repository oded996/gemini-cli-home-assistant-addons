# Antigravity CLI for Home Assistant

A secure, web-based terminal with Google's **Antigravity CLI** (`agy`) pre-installed for Home Assistant.

![Antigravity CLI Screenshot](https://github.com/oded996/gemini-cli-home-assistant-addons/raw/main/gemini-terminal/screenshot.png)

*Antigravity CLI running in Home Assistant*

## What is Antigravity CLI?

This add-on provides a web-based terminal interface pre-installed with Google's official **Antigravity CLI** (`agy`), allowing you to use Antigravity's powerful AI capabilities directly from your Home Assistant dashboard. It gives you direct access to Google's Antigravity AI assistant through a terminal, ideal for:

- **Controlling your Home**: Use natural language to control devices via the built-in MCP server (`mcp_config.json`).
- **Writing and editing code**: Get help with Home Assistant YAML, Python scripts, and more.
- **Debugging problems**: Analyze Home Assistant logs and troubleshoot automation issues.
- **Smart Context**: Antigravity automatically knows about your entities, system info, and recent errors via `GEMINI.md`.

## Features

- **Web Terminal Interface**: Access the terminal using `ttyd` with a polished dark theme.
- **Auto-Launch**: `agy` starts automatically when you open the terminal.
- **Home Assistant MCP**: Pre-configured [ha-mcp](https://github.com/homeassistant-ai/ha-mcp) integration (`mcp_config.json`) for direct control of your home.
- **Headless Auth**: Provide your `gemini_api_key` in the add-on configuration for zero-config startup.
- **Smart Context**: Automatically generates a `GEMINI.md` file with your Home Assistant state for Antigravity to read.
- **Direct Config Access**: Terminal starts in your `/config` directory for immediate access to all Home Assistant files.
- **Session Persistence**: Built-in `tmux` support ensures your session stays alive if you close the browser tab.
- **Persistent Package Management**: Install APK and pip packages that survive container restarts using the `persist-install` command.

## Quick Start

The terminal automatically starts `agy` when you open it. You can immediately start using commands like:

```bash
# Ask Antigravity a question about your home
agy "Which lights are currently on?"

# Start an interactive session (or use 'gemini' alias)
agy

# Resume a previous session
agy -r latest

# Refresh your Home Assistant context
ha-context --full

# Install packages that persist across restarts
persist-install apk vim htop
persist-install pip requests
```

## Installation

1. Add this repository to your Home Assistant add-on store: `https://github.com/oded996/gemini-cli-home-assistant-addons`
2. Install the **Antigravity CLI** add-on.
3. (Optional) Enter your **Gemini API Key** in the configuration tab.
4. Start the add-on.
5. Click "OPEN WEB UI" or use the sidebar icon to access.

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `gemini_api_key` | `""` | Optional Google API key for automatic authentication. |
| `auto_launch_gemini` | `true` | Auto-start Antigravity on terminal open. |
| `enable_ha_mcp` | `true` | Enable the Home Assistant MCP server integration. |
| `ha_smart_context` | `true` | Automatically generate HA context (`GEMINI.md`) for Antigravity. |
| `persistent_apk_packages` | `[]` | List of APK packages to install on startup. |
| `persistent_pip_packages` | `[]` | List of pip packages to install on startup. |

## Credits & Inspiration

This project is a refitted fork of the **[Claude Terminal for Home Assistant](https://github.com/heytcass/home-assistant-addons)** by **[Tom Cassady (@heytcass)](https://github.com/heytcass)**. 

Special thanks to the original author for the excellent foundation in containerized terminal environments and Home Assistant integration.

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details. The Antigravity CLI tool itself is subject to Google's Terms of Service.
