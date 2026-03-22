# GEMINI.md

This file provides guidance to Gemini CLI when working with code in this repository.

## Project Overview

This repository contains Home Assistant add-ons, specifically the **Gemini Terminal** add-on which provides a web-based terminal interface with Gemini CLI pre-installed. The add-on allows Home Assistant users to access Gemini AI capabilities directly from their dashboard.

## Development Environment

### Setup
```bash
# Enter the development shell (NixOS/Nix)
nix develop

# Or with direnv (if installed)
direnv allow
```

### Core Development Commands
- `build-addon` - Build the Gemini Terminal add-on with Podman
- `run-addon` - Run add-on locally on port 7682 with volume mapping
- `lint-dockerfile` - Lint Dockerfile using hadolint
- `test-endpoint` - Test web endpoint availability (curl localhost:7682)

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
- **config.yaml** - Home Assistant add-on configuration (multi-arch, ingress, ports)
- **Dockerfile** - Alpine-based container with Node.js and Gemini Code CLI
- **build.yaml** - Multi-architecture build configuration (amd64, aarch64, armv7)
- **run.sh** - Main startup script with credential management and ttyd terminal
- **scripts/** - Modular credential management scripts

### Key Components
1. **Web Terminal**: Uses ttyd to provide browser-based terminal access
2. **Credential Management**: Persistent authentication storage in `/config/gemini-config/`
3. **Service Integration**: Home Assistant ingress support with panel icon
4. **Multi-Architecture**: Supports amd64, aarch64, armv7 platforms

### Credential System
The add-on implements a sophisticated credential management system:
- **Persistent Storage**: Credentials saved to `/config/gemini-config/` (survives restarts)
- **Multiple Locations**: Handles various Gemini credential file locations
- **Background Service**: Continuous credential monitoring and saving
- **Security**: Proper file permissions (600) and safe directory operations

### Container Execution Flow
1. Initialize environment and create credential directories
2. Install ttyd and tools via apk
3. Setup modular credential management scripts
4. Start background credential monitoring service
5. Launch ttyd web terminal with Gemini auto-start

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

# Stop and cleanup
podman stop test-gemini-dev && podman rm test-gemini-dev
```

#### Interactive Testing
```bash
# Test session picker directly
podman run --rm -it local/gemini-terminal:test /opt/scripts/gemini-session-picker.sh

# Execute commands inside running container
podman exec -it test-gemini-dev /bin/bash

# Test script modifications without rebuilding
podman cp ./gemini-terminal/scripts/gemini-session-picker.sh test-gemini-dev:/opt/scripts/
podman exec test-gemini-dev chmod +x /opt/scripts/gemini-session-picker.sh
```

#### Development Workflow
1. **Make changes** to scripts or Dockerfile
2. **Rebuild** with `podman build -t local/gemini-terminal:test ./gemini-terminal`
3. **Stop/remove** old container: `podman stop test-gemini-dev && podman rm test-gemini-dev`
4. **Start new** container with updated image
5. **Test** changes at http://localhost:7682
6. **Repeat** until satisfied, then commit and push

#### Debugging Tips
- **Check container logs**: `podman logs -f test-gemini-dev` (follow mode)
- **Inspect running processes**: `podman exec test-gemini-dev ps aux`
- **Test individual scripts**: `podman exec test-gemini-dev /opt/scripts/script-name.sh`
- **Volume contents**: `ls -la /tmp/test-config/` to verify persistence

### Production Testing
- **Local Testing**: Use `run-addon` to test on localhost:7682
- **Container Health**: Check logs with `podman logs <container-id>`
- **Authentication**: Use `gemini-auth debug` within terminal for credential troubleshooting

### File Conventions
- **Shell Scripts**: Use `#!/usr/bin/with-contenv bashio` for add-on scripts
- **Indentation**: 2 spaces for YAML, 4 spaces for shell scripts
- **Error Handling**: Use `bashio::log.error` for error reporting
- **Permissions**: Credential files must have 600 permissions

### Key Environment Variables
- `GEMINI_CREDENTIALS_DIRECTORY=/config/gemini-config`
- `GEMINI_CONFIG_DIR=/config/gemini-config`
- `HOME=/root`

### Important Constraints
- No sudo privileges available in development environment
- Add-on targets Home Assistant OS (Alpine Linux base)
- Must handle credential persistence across container restarts
- Requires multi-architecture compatibility