ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Use Home Assistant build arguments
ARG BUILD_ARCH

# Install base requirements
# Explicitly adding nodejs and npm back for Alpine 3.21 compatibility
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
# We use --unsafe-perm to ensure the global binaries are linked correctly
RUN npm install -g --unsafe-perm @google/gemini-cli \
    && npm install -g --unsafe-perm @modelcontextprotocol/server-home-assistant \
    && pip3 install --no-cache-dir ha-mcp==3.5.1 --break-system-packages

# Install Home Assistant CLI for Supervisor access (Architecture Aware)
RUN \
    if [ "${BUILD_ARCH}" = "aarch64" ]; then ARCH="aarch64"; \
    elif [ "${BUILD_ARCH}" = "amd64" ]; then ARCH="amd64"; \
    elif [ "${BUILD_ARCH}" = "armv7" ]; then ARCH="armv7"; \
    elif [ "${BUILD_ARCH}" = "armhf" ]; then ARCH="armhf"; \
    elif [ "${BUILD_ARCH}" = "i386" ]; then ARCH="i386"; \
    else ARCH="amd64"; fi \
    && curl -L -s "https://github.com/home-assistant/cli/releases/download/4.33.0/ha_${ARCH}" -o /usr/local/bin/ha \
    && chmod +x /usr/local/bin/ha

# Copy local scripts and run command
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Set environment variables
ENV GEMINI_TELEMETRY=off \
    GEMINI_CLI_NO_RELAUNCH=1

# Expose the terminal port
EXPOSE 7682

# Start the application
CMD ["/run.sh"]
