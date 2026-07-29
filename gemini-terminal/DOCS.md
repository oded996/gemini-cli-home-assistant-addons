# Antigravity CLI

A terminal interface powered by Google's **Antigravity CLI** (`agy`) in Home Assistant.

## About

This add-on provides a web-based terminal pre-installed with **Antigravity CLI** (`agy`), allowing you to access powerful AI capabilities directly from your Home Assistant dashboard. Following Google's transition from Gemini CLI to Antigravity CLI, `agy` is the official binary powering this terminal, with backward-compatible support for `gemini` command aliases and `GEMINI.md` context files.

## Installation

1. Add this repository to your Home Assistant add-on store: `https://github.com/oded996/gemini-cli-home-assistant-addons`
2. Install the **Antigravity CLI** add-on.
3. Start the add-on.
4. Click **"OPEN WEB UI"** to access the terminal.
5. On first use, follow the prompts to log in to your Google account (or enter a `gemini_api_key` in the configuration for headless login).

## Configuration

Your authentication credentials and session data are stored in the `/data/.config/antigravity` (and `/data/.config/gemini`) directory and will persist across add-on updates and restarts. MCP server configuration is maintained in `mcp_config.json`.

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `gemini_api_key` | `""` | Optional Google API key for headless authentication |
| `gemini_debug` | `false` | Enable verbose debugging and show internal logs in add-on logs |
| `auto_launch_gemini` | `true` | Automatically start Antigravity when opening the terminal |

| `enable_ha_mcp` | `true` | Enable Home Assistant MCP server integration (`mcp_config.json`). |
| `ha_smart_context` | `true` | Automatically generate HA context (`GEMINI.md`) for Antigravity awareness. |
| `persistent_apk_packages` | `[]` | APK packages to install on every startup. |
| `persistent_pip_packages` | `[]` | Python packages to install on every startup. |

## Usage

Antigravity CLI launches automatically when you open the terminal. You can also start the session manually with:

```bash
agy
# or legacy alias:
gemini
```

### Common Commands

- `agy` (or `gemini`) - Start an interactive session.
- `agy --help` - See all available commands.
- `agy -r latest` - Resume your most recent conversation.
- `ha-context --full` - Refresh the Home Assistant context (`GEMINI.md`) with full entity details.
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

## Safety & Guardrails

Antigravity CLI is designed to be powerful but safe. It includes several built-in guardrails to prevent accidental or destructive changes:

### 1. Interactive Approvals
By default, the Gemini CLI will **never** modify a file or execute a shell command without your explicit permission. It will show you a **diff** of the proposed changes and ask for a confirmation (`y/n`).

### 2. Plan Mode (Dry-Run)
If you want to explore solutions without any risk of modification, you can launch Gemini in **Plan Mode**:
```bash
gemini --approval-mode plan
```
In this mode, Gemini can read your configuration and propose changes, but it is strictly forbidden from executing any tools that modify your system or files.

### 3. Home Assistant Backups
Because this add-on operates on your live `/config` directory, we always recommend ensuring you have a recent **Home Assistant backup** before performing major AI-driven refactoring of your YAML files.

## Troubleshooting

- If Gemini doesn't start automatically, try running `gemini` manually.
- If you see `unrecognized option: S` errors, ensure the `coreutils` package is correctly installed (v1.0.4+).
- Check the add-on logs in Home Assistant for any error messages.

## Credits & Inspiration

This project is a refitted fork of the **[Claude Terminal for Home Assistant](https://github.com/heytcass/home-assistant-addons)** by **[Tom Cassady (@heytcass)](https://github.com/heytcass)**. 

Special thanks to the original author for the excellent foundation in containerized terminal environments and Home Assistant integration.

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details. Gemini CLI itself is subject to Google's Terms of Service.
