#!/usr/bin/with-contenv bashio

# Enable strict error handling
set -e
set -o pipefail

# Initialize environment for Gemini CLI using /data (HA best practice)
init_environment() {
    local data_home="/data/home"
    local config_dir="/data/.config"
    local cache_dir="/data/.cache"
    local state_dir="/data/.local/state"
    local gemini_config_dir="/data/.config/gemini"

    bashio::log.info "Initializing Gemini CLI environment..."

    # Create all required directories
    mkdir -p "$data_home" "$config_dir/gemini" "$cache_dir" "$state_dir" "/data/.local"
    chmod 755 "$data_home" "$config_dir" "$cache_dir" "$state_dir" "$gemini_config_dir"

    # Set XDG and application environment variables
    export HOME="$data_home"
    export XDG_CONFIG_HOME="$config_dir"
    export XDG_CACHE_HOME="$cache_dir"
    export XDG_STATE_HOME="$state_dir"
    export XDG_DATA_HOME="/data/.local/share"
    
    # Language and encoding
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    
    # Gemini-specific environment variables
    export GEMINI_CONFIG_DIR="$gemini_config_dir"
    export GEMINI_HOME="/data"
    export GEMINI_TELEMETRY=off
    export GEMINI_MAX_FILE_SIZE_BYTES=1000000 
    
    # Critical for Node.js stability in containers
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
            bashio::log.info "Gemini API key configured"
        fi
    fi

    # Ensure .geminiignore exists
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
blueprints/
*.db
*.log
*.png
*.jpg
*.gz
*.zip
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
    local debug_log="/data/gemini_last_run.log"

    # Kill any zombie sessions
    tmux kill-session -t gemini 2>/dev/null || true

    local gemini_yolo=$(bashio::config 'gemini_yolo' 'true')
    local yolo_flag=""
    [ "$gemini_yolo" = "true" ] && yolo_flag="--approval-mode yolo"

    local gemini_debug=$(bashio::config 'gemini_debug' 'false')
    local debug_flag=""
    [ "$gemini_debug" = "true" ] && debug_flag="--debug"

    # Launch Gemini with --screen-reader to stop UI flickering crashes
    # This is much more stable than TERM=vt100
    local gemini_cmd="${node_bin} --stack-size=10000 ${gemini_bin} --sandbox false --screen-reader --experimental-acp false --raw-output --accept-raw-output-risk ${yolo_flag} ${debug_flag}"
    
    bashio::log.info "Launching Gemini daemon..."
    tmux new-session -d -s gemini "export TERM=xterm-256color; ${gemini_cmd} 2> ${debug_log}; echo ''; echo 'Gemini session ended. Type gemini to restart.'; exec bash"

    # Terminal theme - dark palette with terracotta accents (#d97757)
    local ttyd_theme='{"background":"#1a1b26","foreground":"#c0caf5","cursor":"#d97757","cursorAccent":"#1a1b26","selectionBackground":"#33467c","selectionForeground":"#c0caf5","black":"#15161e","red":"#f7768e","green":"#9ece6a","yellow":"#e0af68","blue":"#7aa2f7","magenta":"#bb9af7","cyan":"#7dcfff","white":"#a9b1d6","brightBlack":"#414868","brightRed":"#f7768e","brightGreen":"#9ece6a","brightYellow":"#e0af68","brightBlue":"#7aa2f7","brightMagenta":"#bb9af7","brightCyan":"#7dcfff","brightWhite":"#c0caf5"}'

    # ttyd now just attaches to the background session.
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 10 \
        --client-option enableReconnect=true \
        --client-option copyOnSelect=true \
        --client-option "theme=${ttyd_theme}" \
        --client-option fontSize=14 \
        bash -c "echo -e '\033[0;36mInitializing Gemini Terminal...\033[0m'; sleep 1; tmux attach-session -t gemini"
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
