# GEMINI.md

This file provides guidance to Gemini CLI when working with code in this repository.

## Project Overview

This repository contains Home Assistant add-ons, specifically the **Gemini Terminal** add-on which provides a web-based terminal interface with the Google **Gemini CLI** pre-installed. The add-on allows Home Assistant users to access Gemini AI capabilities directly from their dashboard.

## Development Environment

### Setup
```bash
# Enter the development shell (NixOS/Nix)
nix develop

# Or with direnv (if installed)
direnv allow
```

### Core Development Commands
- `build-addon` - Build the Gemini Terminal add-on with Podman.
- `run-addon` - Run add-on locally on port 7682 with volume mapping.
- `lint-dockerfile` - Lint Dockerfile using hadolint.
- `test-endpoint` - Test web endpoint availability (curl localhost:7682).

### Manual Commands (without aliases)
```bash
# Build
podman build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.21 -t local/gemini-terminal ./gemini-terminal

# Run locally
podman run -p 7682:7682 -v $(pwd)/config:/config local/gemini-terminal

# Lint
hadolint ./gemini-terminal/Dockerfile

# Test endpoint
curl -X GET http://localhost:7682/
```

## Architecture

### Add-on Structure (gemini-terminal/)
- **config.yaml** - Home Assistant add-on configuration (multi-arch, ingress, ports).
- **Dockerfile** - Alpine-based container with Node.js and Gemini CLI.
- **build.yaml** - Multi-architecture build configuration (amd64, aarch64, armv7).
- **run.sh** - Main startup script with initialization, environment setup, and ttyd terminal.
- **scripts/** - Modular utility scripts (session picker, ha-context, mcp setup).

### Key Components
1. **Web Terminal**: Uses `ttyd` to provide browser-based terminal access.
2. **Credential Management**: Persistent authentication storage in `/data/.config/gemini/`.
3. **Service Integration**: Home Assistant ingress support with panel icon.
4. **Home Assistant MCP**: Native integration for natural language control.
5. **Smart Context**: Generates a `GEMINI.md` context file for system awareness.

### Credential System
The add-on implements a streamlined credential management system:
- **Persistent Storage**: Credentials saved to `/data/.config/gemini/` (survives restarts).
- **API Key Support**: Optional `GEMINI_API_KEY` configuration for headless login.
- **Migration**: Handles legacy credential file locations for backward compatibility.
- **Security**: Proper file permissions (600) for credentials.

### Container Execution Flow
1. **Initialize environment**: Create all required directories in `/data`.
2. **Run Diagnostics**: Verify system resources, network, and CLI availability.
3. **Setup Modular Scripts**: Copy and prepare utility scripts.
4. **Generate HA Context**: Run `ha-context` to create a current `GEMINI.md`.
5. **Setup HA MCP**: Configure the `ha-mcp` server within Gemini CLI.
6. **Launch Web Terminal**: Start `ttyd` with the Gemini launch command.

## Development Notes

### Local Container Testing
For rapid development and debugging without pushing new versions:

#### Quick Build & Test
```bash
# Build test version
podman build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.21 -t local/gemini-terminal:test ./gemini-terminal

# Create test config directory
mkdir -p /tmp/test-config/gemini-config

# Configure session picker (optional)
echo '{"auto_launch_gemini": false}' > /tmp/test-config/options.json

# Run test container
podman run -d --name test-gemini-dev -p 7682:7682 -v /tmp/test-config:/config local/gemini-terminal:test

# Check logs
podman logs test-gemini-dev

# Test web interface at http://localhost:7682
```

### File Conventions
- **Shell Scripts**: Use `#!/usr/bin/with-contenv bashio` for add-on scripts.
- **Indentation**: 2 spaces for YAML, 4 spaces for shell scripts.
- **Error Handling**: Use `bashio::log.error` for error reporting.

### Key Environment Variables
- `GEMINI_CONFIG_DIR=/data/.config/gemini`
- `GEMINI_HOME=/data`
- `HOME=/data/home`
- `GOOGLE_API_KEY` / `GEMINI_API_KEY`

### Important Constraints
- **Alpine coreutils**: Requires `coreutils` package for `env -S` support in shebangs.
- **Home Assistant OS**: Targets Alpine Linux base; must handle persistence in `/data`.
- **Architecture**: Supports amd64, aarch64, armv7.

## Credits & Inspiration

This project is a refitted fork of the **[Claude Terminal for Home Assistant](https://github.com/heytcass/home-assistant-addons)** by **[Tom Cassady (@heytcass)](https://github.com/heytcass)**. 

Special thanks to the original author for the excellent foundation in containerized terminal environments and Home Assistant integration.
