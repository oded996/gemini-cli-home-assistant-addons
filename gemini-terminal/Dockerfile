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

# Install Gemini CLI via npm, then rebuild native modules for Alpine musl libc.
#
# Problem: tree-sitter-bash ships glibc-only prebuilds (prebuilds/linux-x64/).
# node-gyp-build prefers prebuilds/ over build/, so the glibc binary is loaded
# at runtime, causing SIGSEGV (exit 139) when the Shell tool parses bash commands.
#
# Fix: delete the glibc prebuilds, then rebuild from source so node-gyp-build
# falls through to build/Release/ which is compiled against musl.
#
# @lydell/node-pty-linux-x64 is also a glibc prebuild; replace it with the
# musl-compiled pty.node from node-pty/build/Release/.
RUN apk add --no-cache --virtual .build-deps \
    build-base \
    g++ \
    make \
    linux-headers \
    && npm install -g node-gyp @google/gemini-cli@latest \
    && GEMINI_MODS=/usr/local/lib/node_modules/@google/gemini-cli/node_modules \
    # Rebuild tree-sitter-bash for musl
    && TSDIR="$GEMINI_MODS/tree-sitter-bash" \
    && rm -rf "$TSDIR/prebuilds" \
    && cd "$TSDIR" && node-gyp rebuild \
    # Replace @lydell/node-pty-linux-x64 glibc binary with the musl-compiled one
    && LYDELL_PTY="$GEMINI_MODS/@lydell/node-pty-linux-x64/pty.node" \
    && COMPILED_PTY="$GEMINI_MODS/node-pty/build/Release/pty.node" \
    && [ -f "$LYDELL_PTY" ] && [ -f "$COMPILED_PTY" ] && cp "$COMPILED_PTY" "$LYDELL_PTY" || true \
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