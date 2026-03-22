#!/usr/bin/with-contenv bashio

# Enable strict error handling
set -e
set -o pipefail

# Initialize environment for Gemini CLI using /data (HA best practice)
init_environment() {
    # Use /data exclusively - guaranteed writable by HA Supervisor
    local data_home="/data/home"
    local config_dir="/data/.config"
    local cache_dir="/data/.cache"
    local state_dir="/data/.local/state"
    local gemini_config_dir="/data/.config/gemini"

    bashio::log.info "Initializing Gemini CLI environment..."

    # Create required directories
    mkdir -p "$data_home" "$config_dir/gemini" "$cache_dir" "$state_dir" "/data/.local"
    chmod 755 "$data_home" "$config_dir" "$cache_dir" "$state_dir" "$gemini_config_dir"

    # Set environment variables
    export HOME="$data_home"
    export XDG_CONFIG_HOME="$config_dir"
    export XDG_CACHE_HOME="$cache_dir"
    export XDG_STATE_HOME="$state_dir"
    export XDG_DATA_HOME="/data/.local/share"
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    
    # Gemini-specific environment variables
    export GEMINI_CONFIG_DIR="$gemini_config_dir"
    export GEMINI_HOME="/data"
    export GEMINI_TELEMETRY=off
    
    # Use only universally allowed Node options here
    export NODE_OPTIONS="--max-old-space-size=8192 --no-warnings"
    export NODE_NO_WARNINGS=1
    export UV_THREADPOOL_SIZE=64
    
    # Mandatory fix for file watcher crashes
    export FSWATCH_BACKEND="poll"

    # Set Gemini API key
    if bashio::config.has_value 'gemini_api_key'; then
        local api_key=$(bashio::config 'gemini_api_key')
        if [ -n "$api_key" ] && [ "$api_key" != "null" ]; then
            export GOOGLE_API_KEY="$api_key"
            export GEMINI_API_KEY="$api_key"
        fi
    fi

    # Ensure .geminiignore exists
    if [ ! -f "/config/.geminiignore" ]; then
        cat > "/config/.geminiignore" << 'EOF'
.storage/
.git/
.gemini*/
.node_modules/
backups/
addons/
deps/
local/
share/
tts/
www/
blueprints/
*.db
*.log
EOF
    fi
}

# Install required tools
install_tools() {
    bashio::log.info "Installing terminal tools..."
    apk add --no-cache ttyd jq curl tmux coreutils util-linux
}

# Start main web terminal with background persistence
start_web_terminal() {
    local port=7682
    bashio::log.info "Starting Gemini Terminal on port ${port}..."

    # Determine binary paths
    local node_bin=$(which node)
    local gemini_bin=$(which gemini)
    local debug_log="/config/.gemini_logs/last_session.log"
    mkdir -p "/config/.gemini_logs"

    # Kill any zombie sessions
    tmux kill-session -t gemini 2>/dev/null || true

    local auto_launch_gemini=$(bashio::config 'auto_launch_gemini' 'true')
    local gemini_debug=$(bashio::config 'gemini_debug' 'false')
    local debug_flag=""
    [ "$gemini_debug" = "true" ] && debug_flag="--debug"

    # Launch Gemini via explicit node command to bypass NODE_OPTIONS restrictions on stack-size
    local gemini_cmd="${node_bin} --stack-size=10000 ${gemini_bin} --sandbox false --experimental-acp false --raw-output --accept-raw-output-risk ${debug_flag}"
    
    bashio::log.info "Launching Gemini background worker..."
    tmux new-session -d -s gemini "export TERM=xterm-256color; ${gemini_cmd} 2> ${debug_log}; echo ''; echo 'Gemini session ended. Type gemini to restart.'; exec bash"

    # ttyd configuration with forced clipboard support
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 10 \
        --client-option enableReconnect=true \
        --client-option copyOnSelect=true \
        --client-option enableClipboard=true \
        bash -c "echo -e '\033[0;36mAttaching to Gemini session...\033[0m'; sleep 1; tmux attach-session -t gemini"
}

# Setup ha-mcp (Home Assistant MCP Server)
setup_ha_mcp() {
    if [ -f "/opt/scripts/setup-ha-mcp.sh" ]; then
        chmod +x /opt/scripts/setup-ha-mcp.sh
        /opt/scripts/setup-ha-mcp.sh || true
    fi
}

# Main execution
main() {
    init_environment
    install_tools
    setup_ha_mcp
    start_web_terminal
}

main "$@"
