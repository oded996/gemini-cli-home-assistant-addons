# Global ARGs (available in FROM instructions)
ARG BUILD_ARCH=amd64
ARG BUILD_FROM=ghcr.io/home-assistant/${BUILD_ARCH}-base-debian:trixie

## Stage 1: Build hab CLI from source (pinned release)
FROM golang:1.24-trixie AS hab-builder

ARG BUILD_ARCH
ARG HAB_VERSION=1.6.4
RUN git clone --depth 1 --branch "${HAB_VERSION}" https://github.com/balloob/home-assistant-build-cli.git /src
WORKDIR /src

# Cross-compile for the target architecture
RUN GOARCH=$([ "$BUILD_ARCH" = "aarch64" ] && echo "arm64" || echo "amd64") \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /hab .

## Stage 2: Main add-on image
FROM $BUILD_FROM

# Build arguments
ARG BUILD_VERSION
ARG BUILD_ARCH
ARG TTYD_VERSION=1.7.7
ARG OPENCODE_VERSION=latest

# Environment for better Node.js performance
ENV NODE_ENV=production \
    npm_config_update_notifier=false \
    npm_config_fund=false

# Install system dependencies in a single layer
# - nodejs/npm: Required for Gemini CLI
# - git: Required by Gemini CLI for version control operations
# - jq: JSON processing for helper scripts
# - curl/ca-certificates: For downloading ttyd
# - procps: Provides pgrep for health check
# - tmux: Session persistence to prevent multiple Gemini CLI instances
# - chromium: Headless browser for screenshot_url MCP tool (visual verification)
# - nano, vim, tree, yq: User requested terminal tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        chromium \
        curl \
        git \
        jq \
        nodejs \
        npm \
        procps \
        python3 \
        python3-venv \
        tmux \
        nano \
        vim \
        tree \
        yq \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install gh -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Chromium path for puppeteer-core (used by screenshot MCP tool)
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Install ttyd from GitHub releases (not in Debian repos)
RUN ARCH=$([ "$BUILD_ARCH" = "aarch64" ] && echo "aarch64" || echo "x86_64") \
    && curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${ARCH}" -o /usr/bin/ttyd \
    && chmod +x /usr/bin/ttyd

# Copy hab CLI binary built from source (pinned release)
COPY --from=hab-builder /hab /usr/local/bin/hab

# Install zigporter CLI in an isolated Python virtual environment
RUN python3 -m venv /opt/zigporter-venv \
    && /opt/zigporter-venv/bin/pip install --no-cache-dir zigporter \
    && ln -s /opt/zigporter-venv/bin/zigporter /usr/local/bin/zigporter

# Install Antigravity CLI (agy) and Prettier globally
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash \
    && ( for p in /root/.antigravity/bin/agy /root/.local/bin/agy /root/bin/agy /usr/local/bin/agy; do \
           if [ -f "$p" ]; then cp "$p" /usr/local/bin/agy 2>/dev/null || true; break; fi; \
         done ) \
    && chmod +x /usr/local/bin/agy 2>/dev/null || true \
    && npm install -g prettier \
    && npm cache clean --force

# Copy package.json files first for better layer caching
COPY rootfs/opt/ha-mcp-server/package*.json /opt/ha-mcp-server/

# Install MCP dependencies
RUN (cd /opt/ha-mcp-server && npm install --omit=dev) \
    && npm cache clean --force

# Copy root filesystem (server code, scripts, etc.)
COPY rootfs /

# Make scripts executable and create runtime directories
RUN chmod +x /usr/local/bin/* \
    && chmod +x /etc/s6-overlay/s6-rc.d/init-gemini/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/ha-gemini/run \
    && chmod +x /etc/profile.d/hab-esphome.sh \
    && chmod +x /etc/profile.d/zigporter-z2m.sh \
    && mkdir -p /data/.local/share/antigravity /data/.config/antigravity /data/.antigravity /data/.local/share/gemini /data/.config/gemini

# Set working directory to HA config (mounted at runtime)
WORKDIR /homeassistant

# Health check - verify ttyd is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep ttyd > /dev/null || exit 1

# Labels for Home Assistant
LABEL \
    io.hass.name="Antigravity CLI" \
    io.hass.description="Terminal interface for Google's Antigravity CLI (agy) with deep MCP integration" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    org.opencontainers.image.title="Antigravity CLI" \
    org.opencontainers.image.description="Terminal interface for Google's Antigravity CLI (agy) with deep MCP integration" \
    org.opencontainers.image.source="https://github.com/oded996/gemini-cli-home-assistant-addons" \
    org.opencontainers.image.licenses="Apache-2.0"
