ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install base requirements
RUN apk add --no-cache \
    nodejs \
    npm \
    ttyd \
    bash \
    curl \
    git \
    jq \
    tmux \
    coreutils \
    util-linux \
    python3 \
    py3-pip \
    build-base \
    linux-headers \
    github-cli

# Install Gemini CLI and MCP helper globally
# Use --build-from-source to ensure compatibility with Alpine (musl)
RUN npm install -g @google/gemini-cli \
    && npm install -g @modelcontextprotocol/server-home-assistant \
    && pip3 install --no-cache-dir ha-mcp==3.5.1 --break-system-packages

# Rebuild native modules from source to avoid glibc segmentation faults
RUN npm install -g node-gyp \
    && cd /usr/lib/node_modules/@google/gemini-cli \
    && npm rebuild --build-from-source \
    && find . -name "*.node" -exec strip {} +

# Install Home Assistant CLI for Supervisor access
RUN curl -L -s https://github.com/home-assistant/cli/releases/download/4.33.0/ha_amd64 -o /usr/local/bin/ha \
    && chmod +x /usr/local/bin/ha

# Copy root filesystem
COPY rootfs /

# Set environment variables
ENV GEMINI_TELEMETRY=off \
    GEMINI_CLI_NO_RELAUNCH=1

# Expose the terminal port
EXPOSE 7682

# Start the application
CMD ["/run.sh"]
