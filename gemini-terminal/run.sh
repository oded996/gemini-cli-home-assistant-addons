#!/usr/bin/with-contenv bashio

# Enable strict error handling
set -e
set -o pipefail

# Initialize environment
init_environment() {
    local data_home="/data/home"
    local config_dir="/data/.config"
    local gemini_config_dir="/data/.config/gemini"

    bashio::log.info "Initializing Gemini CLI environment..."

    mkdir -p "$data_home" "$config_dir/gemini" "/data/.cache" "/data/.local"
    chmod 755 "$data_home" "$config_dir"

    export HOME="$data_home"
    export XDG_CONFIG_HOME="$config_dir"
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    
    # Gemini Variables
    export GEMINI_CONFIG_DIR="$gemini_config_dir"
    export GEMINI_HOME="/data"
    export GEMINI_TELEMETRY=off
    export GEMINI_MAX_FILE_SIZE_BYTES=1000000 
    
    # Node Stability
    export NODE_OPTIONS="--max-old-space-size=8192 --no-warnings"
    export UV_THREADPOOL_SIZE=64

    # Set Gemini API key
    if bashio::config.has_value 'gemini_api_key'; then
        local api_key=$(bashio::config 'gemini_api_key')
        if [ -n "$api_key" ] && [ "$api_key" != "null" ]; then
            export GOOGLE_API_KEY="$api_key"
            export GEMINI_API_KEY="$api_key"
        fi
    fi

    # Cleanup dangerous folders
    rm -rf /config/gemini-logs /config/.gemini_logs 2>/dev/null || true

    # Force strict ignore rules
    if [ ! -f "/config/.geminiignore" ]; then
        cat > "/config/.geminiignore" << 'EOF'
.storage/
.git/
.gemini*/
backups/
addons/
deps/
local/
share/
tts/
www/
*.db
*.log
EOF
    fi
}

# Start web terminal
start_web_terminal() {
    local port=7682
    bashio::log.info "Starting Gemini Terminal on port ${port}..."

    # Launch Gemini in a background tmux session with LEGACY terminal settings
    # This prevents the UI popups from using mouse features that crash the TTY
    tmux kill-session -t gemini 2>/dev/null || true
    
    local gemini_cmd="gemini --sandbox false --experimental-acp false --raw-output --accept-raw-output-risk"
    
    bashio::log.info "Launching Gemini in Legacy Mode..."
    # We force TERM=vt100 to disable unstable terminal features
    tmux new-session -d -s gemini "export TERM=vt100; ${gemini_cmd}; echo ''; echo 'Session ended.'; exec bash"

    # Start ttyd with CSS injection for text selection
    # We use a custom terminal theme that doesn't block selection
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 10 \
        --client-option "copyOnSelect=true" \
        --client-option "theme={\"background\":\"#000000\",\"foreground\":\"#ffffff\"}" \
        bash -c "echo -e '\033[0;33mTIP: Use Shift + Mouse Selection to copy text.\033[0m'; echo 'Connecting...'; sleep 1; tmux attach-session -t gemini"
}

# Setup ha-mcp
setup_ha_mcp() {
    if [ -f "/opt/scripts/setup-ha-mcp.sh" ]; then
        chmod +x /opt/scripts/setup-ha-mcp.sh
        /opt/scripts/setup-ha-mcp.sh || true
    fi
}

# Main
main() {
    init_environment
    apk add --no-cache ttyd jq curl tmux coreutils util-linux >/dev/null
    setup_ha_mcp
    start_web_terminal
}

main "$@"
