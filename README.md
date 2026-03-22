# Gemini Terminal for Home Assistant

This repository contains a custom add-on that integrates Google's **Gemini CLI** with Home Assistant.

## Installation

To add this repository to your Home Assistant instance:

1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the three dots menu (top right corner)
3. Select **Repositories**
4. Add the URL: `https://github.com/oded996/gemini-cli-home-assistant-addons`
5. Click **Add**

## Add-ons

### Gemini Terminal

A web-based terminal interface with the Google Gemini CLI pre-installed. This add-on provides a powerful AI-driven terminal environment directly in your Home Assistant dashboard.

**Key Features:**
- **Web Terminal**: Access a full terminal via your browser with a polished dark theme.
- **Auto-Authentication**: Supports `GEMINI_API_KEY` configuration via the add-on UI for headless login.
- **Home Assistant MCP**: Pre-installed [ha-mcp](https://github.com/homeassistant-ai/ha-mcp) server for natural language control of your entities.
- **Smart Context**: Automatically generates a `GEMINI.md` context file with your system info, entities, and recent errors.
- **Session Persistence**: Built-in `tmux` support ensures your conversations persist even if you navigate away.
- **Direct Config Access**: Starts directly in your `/config` directory for easy YAML editing.

[Full Documentation](gemini-terminal/DOCS.md) | [Changelog](gemini-terminal/CHANGELOG.md)

## Credits & Inspiration

This project is a fork of the excellent **[Claude Terminal for Home Assistant](https://github.com/heytcass/home-assistant-addons)** by **[Tom Cassady (@heytcass)](https://github.com/heytcass)**. 

While the original project focuses on Anthropic's Claude Code, this version has been completely refitted to support Google's Gemini CLI ecosystem, while maintaining the same great user experience and Home Assistant integrations.

## Support

If you have any questions or issues, please create an issue in this repository.

## License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. Gemini CLI itself is subject to Google's Terms of Service.
