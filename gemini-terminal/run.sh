#!/usr/bin/with-contenv bashio

# Enable strict error handling
set -e
set -o pipefail

# Initialize environment for Gemini CLI
init_environment() {
    local data_home="/data/home"
    local config_dir="/data/.config"
    local gemini_config_dir="/data/.config/gemini"
    local gemini_user_dir="$data_home/.gemini"

    bashio::log.info "Initializing Gemini CLI environment..."

    mkdir -p "$data_home" "$config_dir/gemini" "$gemini_user_dir" "/data/.cache" "/data/.local"
    chmod 755 "$data_home" "$config_dir" "$gemini_user_dir"

    export HOME="$data_home"
    export XDG_CONFIG_HOME="$config_dir"
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    
    # Gemini Variables
    export GEMINI_CONFIG_DIR="$gemini_config_dir"
    export GEMINI_HOME="/data"
    export GEMINI_TELEMETRY=off
    
    # Force the CLI to follow our stability rules via its own settings file
    # This prevents it from ignoring our command line flags
    cat > "$gemini_user_dir/settings.json" << 'EOF'
{
  "approvalMode": "yolo",
  "screenReader": true,
  "telemetry": "off",
  "experimentalAcp": false
}
EOF

    # Node Stability
    export NODE_OPTIONS="--max-old-space-size=8192 --no-warnings"
    export UV_THREADPOOL_SIZE=64
    export FSWATCH_BACKEND="poll"

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

    # Determine binary paths
    local node_bin=$(which node)
    local gemini_bin=$(which gemini)
    local debug_log="/data/gemini_last_run.log"

    # Kill any zombie sessions
    tmux kill-session -t gemini 2>/dev/null || true

    # Launch Gemini in a background worker
    # We use --approval-mode yolo twice (flag and settings) to be 100% sure
    local gemini_cmd="${node_bin} --stack-size=10000 ${gemini_bin} --sandbox false --screen-reader --approval-mode yolo --raw-output --accept-raw-output-risk"
    
    bashio::log.info "Launching Gemini background worker..."
    tmux new-session -d -s gemini "export TERM=xterm-256color; ${gemini_cmd} 2> ${debug_log}; echo ''; echo 'Gemini session ended. Type gemini to restart.'; exec bash"

    # Terminal theme - dark palette
    local ttyd_theme='{"background":"#1a1b26","foreground":"#c0caf5","cursor":"#d97757"}'

    # ttyd now just attaches to the background session.
    # We use rendererType=webgl which is often better for mouse selection
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 5 \
        --client-option enableReconnect=true \
        --client-option copyOnSelect=true \
        --client-option rendererType=webgl \
        --client-option "theme=${ttyd_theme}" \
        bash -c "echo -e '\033[0;36mInitializing persistent Gemini session...\033[0m'; sleep 1; tmux attach-session -t gemini"
}

# Setup ha-mcp
setup_ha_mcp() {
    if [ -f "/opt/scripts/setup-ha-mcp.sh" ]; then
        chmod +x /opt/scripts/setup-ha-mcp.sh
        /opt/scripts/setup-ha-mcp.sh || true
    fi
}

# Main execution
main() {
    init_environment
    apk add --no-cache ttyd jq curl tmux coreutils util-linux >/dev/null
    setup_ha_mcp
    start_web_terminal
}

main "$@"
