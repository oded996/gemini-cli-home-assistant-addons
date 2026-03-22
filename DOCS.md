# Gemini Terminal Home Assistant Add-on Documentation

## Overview

Gemini Terminal provides a web-based terminal interface with Gemini Code CLI pre-installed, allowing you to access Gemini's powerful AI capabilities directly from your Home Assistant dashboard. Gemini Code is an AI coding assistant by Google that can help you with Home Assistant configuration, automation creation, debugging, and general coding tasks.

## Installation

Follow these steps to install the add-on:

1. Navigate to your Home Assistant instance
2. Go to Settings -> Add-ons -> Add-on Store
3. Click the three dots in the top right corner and select "Repositories"
4. Add the URL of this repository and click "Add"
5. Find the "Gemini Terminal" add-on and click on it
6. Click "Install"

## Configuration

No configuration is needed! The add-on uses OAuth authentication, so you'll be prompted to log in to your Google account the first time you use it.

## Usage

The Gemini Code CLI launches automatically when you open the terminal. You can interact with it using the following commands:

### Common Commands

- `gemini -i` - Start an interactive Gemini session
- `gemini --help` - See all available commands
- `gemini "your prompt"` - Ask Gemini a single question
- `gemini process myfile.py` - Have Gemini analyze a file
- `gemini --editor` - Start an interactive editor session

All your files are stored in `/config/gemini-code`, which persists between restarts.

## Home Assistant-Specific Use Cases

Gemini Terminal is particularly useful for Home Assistant tasks. Here are some example uses:

### 1. Automation Creation and Debugging

```
# Create a new automation
gemini "create an automation that turns on lights when motion is detected, but only if it's dark"

# Debug an existing automation
gemini "why isn't my automation working? Here's the code: [paste automation code]"
```

### 2. YAML Configuration Help

```
# Get help with syntax
gemini "what's wrong with this YAML? [paste YAML]"

# Create a new configuration
gemini "create a configuration for a zigbee device with these capabilities: [list capabilities]"
```

### 3. Entity Management

```
# Clean up entity names
gemini "suggest better names for these entities: [paste entity list]"

# Create a template sensor
gemini "create a template sensor that averages these temperature sensors: [paste sensor IDs]"
```

### 4. Custom Component Development

```
# Create a new integration
gemini "help me create a custom integration for my smart coffee maker"

# Debug integration issues
gemini "why is my custom component failing to load? Here's the error: [paste error]"
```

## Troubleshooting

### Common Issues

1. **Authentication Issues**: 
   - If you're having trouble with OAuth login, try clearing your browser cookies
   - Make sure you have a valid Google account with billing enabled

2. **Connection Problems**: 
   - Check your internet connection
   - Verify the add-on can reach api.google.com

3. **Terminal Connection Issues**:
   - If the terminal disconnects, try refreshing the page
   - Check if the add-on is still running in Home Assistant

### Logs

Check the add-on logs for detailed information about any issues:

1. Go to the add-on page in Home Assistant
2. Click the "Logs" tab

## Security Considerations

Gemini Terminal is designed with security in mind:

- The add-on runs in an isolated container
- Your code and queries go directly to Google's API
- OAuth authentication ensures secure access to your account

To further enhance security:
- Log out when not actively using the terminal
- Monitor the add-on logs for unusual activity
- Keep your Google account secure with a strong password

## Support

- For issues with the add-on itself, please open an issue on the GitHub repository
- For Gemini Code-specific issues, refer to the [Google documentation](https://docs.google.com/gemini-code)
- For billing or API questions, visit [Google's support site](https://support.google.com)

## Credits

This add-on was created with the assistance of Gemini Code itself! The entire development process, debugging, and documentation were all completed using Gemini's AI capabilities.

## License

This add-on is provided under the MIT License. Gemini Code itself is subject to Google's Commercial Terms of Service.
