ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install system packages and development tools
RUN apk add --no-cache \
    bash \
    curl \
    nano \
    nodejs \
    npm \
    python3 \
    py3-pip \
    py3-requests \
    py3-aiohttp \
    py3-yaml \
    py3-beautifulsoup4 \
    git \
    vim \
    wget \
    jq \
    tree \
    tmux \
    yq \
    coreutils \
    util-linux

# Install Gemini CLI via npm.
# linux-headers is required by node-pty (PTY native module used by the Shell tool).
# npm_config_build_from_source=true forces ALL native modules to compile from
# source against Alpine's musl libc instead of using pre-built glibc binaries,
# which segfault (SIGSEGV/exit 139) on Alpine.
RUN apk add --no-cache --virtual .build-deps \
    build-base \
    g++ \
    make \
    linux-headers \
    && npm_config_build_from_source=true npm install -g @google/gemini-cli@latest \
    && npm cache clean --force \
    && apk del --no-cache .build-deps

# Install uv for running ha-mcp (Python package manager/runner)
RUN apk add --no-cache uv

# Pre-install ha-mcp to ensure it's ready to use
RUN pip3 install --break-system-packages --no-cache-dir ha-mcp==3.5.1

# Create directory for Gemini configuration and set working directory
RUN mkdir -p /config/gemini-config
WORKDIR /config

# Copy startup script and modular scripts
COPY run.sh /run.sh
COPY scripts/ /opt/scripts/
RUN chmod +x /run.sh \
    && chmod +x /opt/scripts/*.sh

# Use exec form for better signal handling
CMD ["/run.sh"]