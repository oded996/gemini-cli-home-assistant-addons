# Antigravity CLI Home Assistant Add-on Documentation

## Overview

Antigravity CLI provides a web-based terminal interface pre-installed with Google's official **Antigravity CLI** (`agy`), allowing you to access powerful AI capabilities directly from your Home Assistant dashboard. Antigravity CLI is an AI coding assistant by Google that can help you with Home Assistant configuration, automation creation, debugging, and general coding tasks.

## Installation

Follow these steps to install the add-on:

1. Navigate to your Home Assistant instance
2. Go to **Settings** -> **Add-ons** -> **Add-on Store**
3. Click the three dots (top right corner) and select **"Repositories"**
4. Add the URL of this repository: `https://github.com/oded996/gemini-cli-home-assistant-addons` and click **"Add"**
5. Find the **"Antigravity CLI"** add-on and click on it
6. Click **"Install"**

## Configuration

The add-on works out of the box using OAuth authentication. However, you can also provide a `gemini_api_key` in the configuration tab for a "headless" login experience.

## Usage

Antigravity CLI launches automatically when you open the terminal. You can interact with it using the following commands:

### Common Commands

- `agy` (or `gemini`) - Start an interactive session
- `agy --help` - See all available commands
- `agy "your prompt"` - Ask a single question or provide a direct command
- `agy -r latest` - Resume your most recent conversation
- `ha-context --full` - Refresh the Home Assistant context (`GEMINI.md`) with full entity details

Your session data and configuration are stored in `/data/.config/antigravity` (and `/data/.config/gemini`), which persists between restarts.

## Home Assistant-Specific Use Cases

Antigravity CLI is particularly useful for Home Assistant tasks. Because it has a built-in **MCP (Model Context Protocol)** server and access to a generated **GEMINI.md** context file, it knows your system intimately.

### 1. Automation Creation and Debugging

```
# Ask about your home state
agy "Which lights are currently on?"

# Create a new automation
agy "create an automation that turns on the porch lights when the front door opens, but only after sunset"
```

### 2. YAML Configuration Help

```bash
# Get help with syntax
agy "what's wrong with this YAML? [paste YAML]"

# Analyze your current config
agy "Analyze my /config/configuration.yaml and suggest improvements"
```

### 3. Entity Management

```bash
# Clean up entity names
agy "suggest better names for these entities: [paste entity list]"

# Create a template sensor
agy "create a template sensor that averages all my temperature sensors"
```

---

## Safety & Guardrails

Antigravity CLI is designed to be powerful but safe. It includes several built-in guardrails to prevent accidental or destructive changes:

### 1. Interactive Approvals
By default, `agy` will **never** modify a file or execute a shell command without your explicit permission. It will show you a **diff** of the proposed changes and ask for a confirmation (`y/n`).

### 2. Plan Mode (Dry-Run)
If you want to explore solutions without any risk of modification, you can launch in **Plan Mode**:
```bash
agy --approval-mode plan
```
In this mode, `agy` can read your configuration and propose changes, but it is strictly forbidden from executing any tools that modify your system or files.

### 3. Home Assistant Backups
Because this add-on operates on your live `/config` directory, we always recommend ensuring you have a recent **Home Assistant backup** before performing major AI-driven refactoring of your YAML files.

## Troubleshooting

### Logs

Check the add-on logs for detailed information about any issues:

1. Go to the add-on page in Home Assistant
2. Click the **"Logs"** tab

## Security Considerations

Antigravity CLI is designed with security in mind:

- The add-on runs in an isolated container.
- Your code and queries go directly to Google's API.
- The `ha-mcp` integration uses the internal Supervisor token for secure Home Assistant access.

## Credits & Inspiration

This project is a refitted fork of the **[Claude Terminal for Home Assistant](https://github.com/heytcass/home-assistant-addons)** by **[Tom Cassady (@heytcass)](https://github.com/heytcass)**. 

Special thanks to the original author for the excellent foundation in containerized terminal environments and Home Assistant integration.

## Support

- For issues with the add-on itself, please open an issue on the GitHub repository.
- For Gemini CLI-specific issues, refer to the [Google documentation](https://github.com/google/gemini-cli).

## License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. Gemini CLI itself is subject to Google's Terms of Service.
