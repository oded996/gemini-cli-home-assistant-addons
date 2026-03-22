# Gemini Terminal for Home Assistant

A secure, web-based terminal with the Google Gemini CLI pre-installed for Home Assistant.

![Gemini Terminal Screenshot](https://github.com/oded996/gemini-cli-home-assistant-addons/raw/main/gemini-terminal/screenshot.png)

*Gemini Terminal running in Home Assistant*

## What is Gemini Terminal?

This add-on provides a web-based terminal interface with the Google Gemini CLI pre-installed, allowing you to use Gemini's powerful AI capabilities directly from your Home Assistant dashboard. It gives you direct access to Google's Gemini AI assistant through a terminal, ideal for:

- **Controlling your Home**: Use natural language to control devices via the built-in MCP server.
- **Writing and editing code**: Get help with Home Assistant YAML, Python scripts, and more.
- **Debugging problems**: Analyze Home Assistant logs and troubleshoot automation issues.
- **Smart Context**: Gemini automatically knows about your entities, system info, and recent errors.

## Features

- **Web Terminal Interface**: Access Gemini through a browser-based terminal using `ttyd` with a polished dark theme.
- **Auto-Launch**: Gemini starts automatically when you open the terminal.
- **Home Assistant MCP**: Pre-configured [ha-mcp](https://github.com/homeassistant-ai/ha-mcp) integration for direct control of your home.
- **Headless Auth**: Provide your `gemini_api_key` in the add-on configuration for zero-config startup.
- **Smart Context**: Automatically generates a `GEMINI.md` file with your Home Assistant state for the AI to read.
- **Direct Config Access**: Terminal starts in your `/config` directory for immediate access to all Home Assistant files.
- **Session Persistence**: Built-in `tmux` support ensures your session stays alive if you close the browser tab.
- **Persistent Package Management**: Install APK and pip packages that survive container restarts using the `persist-install` command.

## Quick Start

The terminal automatically starts Gemini when you open it. You can immediately start using commands like:

```bash
# Ask Gemini a question about your home
gemini "Which lights are currently on?"

# Start an interactive session
gemini

# Resume a previous session
gemini -r latest

# Refresh your Home Assistant context
ha-context --full

# Install packages that persist across restarts
persist-install apk vim htop
persist-install pip requests
```

## Installation

1. Add this repository to your Home Assistant add-on store: `https://github.com/oded996/gemini-cli-home-assistant-addons`
2. Install the **Gemini Terminal** add-on.
3. (Optional) Enter your **Gemini API Key** in the configuration tab.
4. Start the add-on.
5. Click "OPEN WEB UI" or use the sidebar icon to access.

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `gemini_api_key` | `""` | Optional Google API key for automatic authentication. |
| `auto_launch_gemini` | `true` | Auto-start Gemini on terminal open. |
| `enable_ha_mcp` | `true` | Enable the Home Assistant MCP server integration. |
| `ha_smart_context` | `true` | Automatically generate HA context for Gemini. |
| `persistent_apk_packages` | `[]` | List of APK packages to install on startup. |
| `persistent_pip_packages` | `[]` | List of pip packages to install on startup. |

## Credits & Inspiration

This project is a refitted fork of the **[Claude Terminal for Home Assistant](https://github.com/heytcass/home-assistant-addons)** by **[Tom Cassady (@heytcass)](https://github.com/heytcass)**. 

Special thanks to the original author for the excellent foundation in containerized terminal environments and Home Assistant integration.

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details. Gemini CLI itself is subject to Google's Terms of Service.
