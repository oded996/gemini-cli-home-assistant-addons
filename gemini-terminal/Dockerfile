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

# Install Home Assistant CLI for Supervisor access (Architecture Aware)
RUN \
    case $(uname -m) in \
        x86_64) export ARCH="amd64" ;; \
        aarch64) export ARCH="aarch64" ;; \
        armv7l) export ARCH="armv7" ;; \
        *) export ARCH="amd64" ;; \
    esac \
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
