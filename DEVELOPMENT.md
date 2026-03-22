# Development Guide

This guide covers local development and testing workflows for the Gemini Terminal add-on.

## Local Container Testing

### Prerequisites

- **Podman** (or Docker) installed
- **Git** repository cloned locally
- **NixOS development environment** (optional, for `nix develop`)

### Quick Start Testing

The fastest way to test changes without publishing new versions:

```bash
# 1. Build test container
podman build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.21 \
  -t local/gemini-terminal:test ./gemini-terminal

# 2. Create test configuration
mkdir -p /tmp/test-config/gemini-config
echo '{"auto_launch_gemini": false}' > /tmp/test-config/options.json

# 3. Run test container
podman run -d --name test-gemini-dev \
  -p 7682:7682 \
  -v /tmp/test-config:/config \
  local/gemini-terminal:test

# 4. Check startup logs
podman logs test-gemini-dev

# 5. Test in browser: http://localhost:7682

# 6. Clean up when done
podman stop test-gemini-dev && podman rm test-gemini-dev
```

### Development Workflow

#### 1. Iterative Development

```bash
# Make changes to code
vim gemini-terminal/scripts/gemini-session-picker.sh

# Rebuild image
podman build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.21 \
  -t local/gemini-terminal:test ./gemini-terminal

# Stop old container
podman stop test-gemini-dev && podman rm test-gemini-dev

# Start new container with changes
podman run -d --name test-gemini-dev -p 7682:7682 \
  -v /tmp/test-config:/config local/gemini-terminal:test

# Test changes
open http://localhost:7682
```

#### 2. Hot-reload Script Testing

For script changes without full rebuilds:

```bash
# Copy updated script to running container
podman cp ./gemini-terminal/scripts/gemini-session-picker.sh \
  test-gemini-dev:/opt/scripts/gemini-session-picker.sh

# Make executable
podman exec test-gemini-dev chmod +x /opt/scripts/gemini-session-picker.sh

# Test directly
podman exec -it test-gemini-dev /opt/scripts/gemini-session-picker.sh
```

### Testing Scenarios

#### Session Picker Testing

```bash
# Test with auto-launch disabled
echo '{"auto_launch_gemini": false}' > /tmp/test-config/options.json

# Test with auto-launch enabled (default)
echo '{"auto_launch_gemini": true}' > /tmp/test-config/options.json
# OR
rm /tmp/test-config/options.json
```

#### Authentication Testing

```bash
# Start with clean credentials
rm -rf /tmp/test-config/gemini-config/*

# Pre-populate credentials for testing
cp ~/.config/google/* /tmp/test-config/gemini-config/
```

#### Multi-session Testing

```bash
# Run multiple containers on different ports
podman run -d --name test-gemini-dev-8681 -p 8681:7682 -v /tmp/test-config-2:/config local/gemini-terminal:test
podman run -d --name test-gemini-dev-9681 -p 9681:7682 -v /tmp/test-config-3:/config local/gemini-terminal:test
```

### Debugging Techniques

#### Container Inspection

```bash
# Follow logs in real-time
podman logs -f test-gemini-dev

# Execute shell inside container
podman exec -it test-gemini-dev /bin/bash

# Check running processes
podman exec test-gemini-dev ps aux

# Inspect environment variables
podman exec test-gemini-dev env | grep GEMINI
```

#### Script Debugging

```bash
# Test session picker with debug output
podman exec -it test-gemini-dev bash -x /opt/scripts/gemini-session-picker.sh

# Test startup script components
podman exec test-gemini-dev /usr/local/bin/gemini-session-picker

# Check file permissions and locations
podman exec test-gemini-dev ls -la /opt/scripts/
podman exec test-gemini-dev ls -la /config/gemini-config/
```

#### Network Testing

```bash
# Test web endpoint
curl -I http://localhost:7682

# Test WebSocket connection
curl --include --no-buffer \
  --header "Connection: Upgrade" \
  --header "Upgrade: websocket" \
  --header "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
  --header "Sec-WebSocket-Version: 13" \
  http://localhost:7682/ws
```

### Performance Testing

#### Resource Usage

```bash
# Monitor container resources
podman stats test-gemini-dev

# Check container size
podman images local/gemini-terminal:test

# Inspect layers
podman history local/gemini-terminal:test
```

#### Load Testing

```bash
# Multiple concurrent connections
for i in {1..5}; do
  curl http://localhost:7682 &
done
wait
```

### Common Issues & Solutions

#### Port Already In Use
```bash
# Find and kill process using port 7682
sudo lsof -ti:7682 | xargs kill -9

# Or use different port
podman run -d --name test-gemini-dev -p 7682:7682 -v /tmp/test-config:/config local/gemini-terminal:test
```

#### Volume Mount Issues
```bash
# Ensure directory exists and has correct permissions
mkdir -p /tmp/test-config/gemini-config
chmod 755 /tmp/test-config/gemini-config

# Check SELinux labels (if applicable)
ls -laZ /tmp/test-config/
```

#### Build Cache Issues
```bash
# Force rebuild without cache
podman build --no-cache --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.21 \
  -t local/gemini-terminal:test ./gemini-terminal

# Clean up unused images
podman image prune
```

### Cleanup Commands

#### Clean Up Test Environment
```bash
# Stop and remove test containers
podman stop test-gemini-dev && podman rm test-gemini-dev

# Remove test configurations
rm -rf /tmp/test-config*

# Clean up test images
podman rmi local/gemini-terminal:test
```

#### Full System Cleanup
```bash
# Remove all stopped containers
podman container prune

# Remove unused images
podman image prune

# Remove unused volumes
podman volume prune
```

## Production Deployment

Once testing is complete:

```bash
# Commit changes
git add .
git commit -m "feature: description of changes"

# Update version in config.yaml
vim gemini-terminal/config.yaml

# Push to main branch
git push origin main
```

The changes will automatically be built and distributed to Home Assistant users.

## Advanced Testing

### Integration with Home Assistant

```bash
# Test with real Home Assistant config structure
mkdir -p /tmp/ha-config/{.storage,gemini-config}
echo '{"auto_launch_gemini": false}' > /tmp/ha-config/options.json

podman run -d --name test-ha-gemini -p 7682:7682 \
  -v /tmp/ha-config:/config local/gemini-terminal:test
```

### Cross-Platform Testing

```bash
# Test different base images
podman build --build-arg BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.21 \
  -t local/gemini-terminal:arm64 ./gemini-terminal

podman build --build-arg BUILD_FROM=ghcr.io/home-assistant/armv7-base:3.21 \
  -t local/gemini-terminal:armv7 ./gemini-terminal
```