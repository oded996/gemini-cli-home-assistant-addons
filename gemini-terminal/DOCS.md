# Gemini Terminal

A terminal interface for Google's Gemini CLI in Home Assistant.

## About

This add-on provides a web-based terminal with the Google Gemini CLI pre-installed, allowing you to access Gemini's powerful AI capabilities directly from your Home Assistant dashboard. The terminal provides full access to Gemini's code generation, explanation, and problem-solving capabilities, with deep integration into Home Assistant.

## Installation

1. Add this repository to your Home Assistant add-on store: `https://github.com/oded996/gemini-cli-home-assistant-addons`
2. Install the **Gemini Terminal** add-on.
3. Start the add-on.
4. Click **"OPEN WEB UI"** to access the terminal.
5. On first use, follow the OAuth prompts to log in to your Google account (or enter a `gemini_api_key` in the configuration for headless login).

## Configuration

Your authentication credentials and session data are stored in the `/data/.config/gemini` directory and will persist across add-on updates and restarts.

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `gemini_api_key` | `""` | Optional Google Gemini API key for headless authentication. |
| `auto_launch_gemini` | `true` | Automatically start Gemini when opening the terminal. |
| `enable_ha_mcp` | `true` | Enable Home Assistant MCP server integration. |
| `ha_smart_context` | `true` | Automatically generate HA context (`GEMINI.md`) for AI awareness. |
| `persistent_apk_packages` | `[]` | APK packages to install on every startup. |
| `persistent_pip_packages` | `[]` | Python packages to install on every startup. |

## Usage

Gemini launches automatically when you open the terminal. You can also start Gemini manually with:

```bash
gemini
```

### Common Commands

- `gemini` - Start an interactive Gemini session.
- `gemini --help` - See all available commands.
- `gemini -r latest` - Resume your most recent conversation.
- `ha-context --full` - Refresh the Home Assistant context (`GEMINI.md`) with full entity details.

The terminal starts directly in your `/config` directory, giving you immediate access to all your Home Assistant configuration files. This makes it easy to get help with your configuration, create automations, and troubleshoot issues.

## Features

- **Web Terminal**: Access a full terminal environment via your browser with a polished dark theme.
- **Auto-Launching**: Gemini starts automatically when you open the terminal.
- **Home Assistant MCP Server**: Built-in integration with [ha-mcp](https://github.com/homeassistant-ai/ha-mcp) for natural language control.
- **Smart Context**: Automatically generates a `GEMINI.md` context file for system and entity awareness.
- **Session Persistence**: Built-in `tmux` support ensures your session stays alive.
- **Direct Config Access**: Terminal starts in `/config` for immediate access to Home Assistant YAML files.

## Home Assistant MCP Integration

This add-on includes the [homeassistant-ai/ha-mcp](https://github.com/homeassistant-ai/ha-mcp) MCP server, enabling Gemini to directly interact with your Home Assistant instance using natural language.

### What You Can Do

- **Control Devices**: "Turn off the living room lights", "Set the thermostat to 72°F"
- **Query States**: "What's the temperature in the bedroom?", "Is the front door locked?"
- **Manage Automations**: "Create an automation that turns on the porch light at sunset"
- **Work with Scripts**: "Run my movie mode script", "Create a script for my morning routine"
- **View History**: "Show me the energy usage for the last week"

### How It Works

The MCP (Model Context Protocol) server automatically connects to your Home Assistant using the Supervisor API. No manual configuration or token setup is required - it just works!

## Troubleshooting

- If Gemini doesn't start automatically, try running `gemini` manually.
- If you see `unrecognized option: S` errors, ensure the `coreutils` package is correctly installed (v1.0.4+).
- Check the add-on logs in Home Assistant for any error messages.

## Credits & Inspiration

This project is a refitted fork of the **[Claude Terminal for Home Assistant](https://github.com/heytcass/home-assistant-addons)** by **[Tom Cassady (@heytcass)](https://github.com/heytcass)**. 

Special thanks to the original author for the excellent foundation in containerized terminal environments and Home Assistant integration.

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details. Gemini CLI itself is subject to Google's Terms of Service.
