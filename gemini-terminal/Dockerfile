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
    util-linux \
    github-cli \
    gcompat

# Install Gemini CLI via npm, then rebuild all native modules for Alpine musl libc.
# 
# Problem: Many native modules (tree-sitter, node-pty) ship glibc-only prebuilds.
# On Alpine (musl), loading these causes SIGSEGV (Segmentation Fault).
#
# Fix: 
# 1. Install the CLI and its dependencies.
# 2. Find and delete ALL 'prebuilds' and 'bin' directories containing glibc binaries.
# 3. Run 'npm rebuild' to compile everything from source against musl.
RUN apk add --no-cache --virtual .build-deps \
    build-base \
    g++ \
    make \
    linux-headers \
    && npm install -g node-gyp @google/gemini-cli@latest \
    && GEMINI_MODS=/usr/local/lib/node_modules/@google/gemini-cli/node_modules \
    && cd /usr/local/lib/node_modules/@google/gemini-cli \
    # Remove all existing prebuilds to force compilation
    && find . -name "prebuilds" -type d -exec rm -rf {} + \
    # Specifically handle node-pty which uses a different structure
    && find . -name "*.node" -path "*/@lydell/*" -delete \
    # Rebuild everything from source
    && npm rebuild --build-from-source \
    && npm cache clean --force \
    && apk del --no-cache .build-deps

# Install ha CLI so Gemini can run 'ha' commands to control Home Assistant.
# The binary connects to http://supervisor/ using $SUPERVISOR_TOKEN, both of
# which are automatically available inside HA add-on containers.
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64)  HA_ARCH="amd64" ;; \
        aarch64) HA_ARCH="aarch64" ;; \
        armv7l)  HA_ARCH="armv7" ;; \
        *) echo "Unsupported arch for ha CLI: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL -o /usr/local/bin/ha \
        "https://github.com/home-assistant/cli/releases/latest/download/ha_${HA_ARCH}" && \
    chmod +x /usr/local/bin/ha

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
