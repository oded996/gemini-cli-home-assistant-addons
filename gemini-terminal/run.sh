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

    mkdir -p "$data_home" "$config_dir/gemini" "$gemini_user_dir/logs" "/data/.cache" "/data/.local"
    chmod 755 "$data_home" "$config_dir" "$gemini_user_dir"

    export HOME="$data_home"
    export XDG_CONFIG_HOME="$config_dir"
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    
    # Gemini Variables
    export GEMINI_CONFIG_DIR="$gemini_config_dir"
    export GEMINI_HOME="/data"
    export GEMINI_TELEMETRY=off
    
    # Stable settings
    cat > "$gemini_user_dir/settings.json" << 'EOF'
{
  "approvalMode": "default",
  "screenReader": false
}
EOF

    # Node Stability
    export NODE_OPTIONS="--max-old-space-size=4096 --no-warnings"
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

    # Ensure .geminiignore is aggressive
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
node_modules/
*.db
*.log
EOF
    fi
}

# Start web terminal
start_web_terminal() {
    local port=7682
    bashio::log.info "Starting Gemini Terminal on port ${port}..."

    # Create the internal loop wrapper
    # This ensures the window NEVER closes, even if Gemini crashes
    cat > /usr/local/bin/gemini-loop << 'EOF'
#!/bin/bash
export TERM=xterm-256color
while true; do
    # Force disable mouse tracking at the start of every session
    # This is a low-level ANSI command that helps with Copy/Paste
    printf '\e[?1000l' 
    
    echo -e "\033[0;36mStarting Gemini CLI (Interactive Mode)...\033[0m"
    
    # We use 'script' to provide a clean PTY for the Node.js engine
    # -q: quiet, -c: command, /dev/null: ignore typescript log
    script -q -c "/usr/local/bin/gemini --sandbox false --acp false --raw-output --accept-raw-output-risk $@" /dev/null
    
    EXIT_CODE=$?
    echo ""
    echo "------------------------------------------------"
    echo -e "\033[0;31mGemini session finished with Exit Code: $EXIT_CODE\033[0m"
    echo "Searching for internal diagnostic logs..."
    LATEST_LOG=$(find /data -name "*.log" -path "*/.gemini/logs/*" -type f -mmin -2 | head -n 1)
    if [ -n "$LATEST_LOG" ]; then
        cp "$LATEST_LOG" /config/gemini_internal_trace.log
        echo "Internal trace extracted to: /config/gemini_internal_trace.log"
    fi
    echo "Terminal will stay open. Type 'gemini' to restart manually."
    echo "------------------------------------------------"
    # Wait for user input so the screen doesn't clear immediately
    read -p "Press Enter to drop to shell..."
    /bin/bash
done
EOF
    chmod +x /usr/local/bin/gemini-loop

    # Get user configuration
    local gemini_debug=$(bashio::config 'gemini_debug' 'false')
    local debug_flag=""
    [ "$gemini_debug" = "true" ] && debug_flag="--debug"

    # Run ttyd: we use the loop script to keep the session alive
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 2 \
        --client-option enableReconnect=true \
        --client-option copyOnSelect=true \
        --client-option "theme={\"background\":\"#1a1b26\",\"foreground\":\"#c0caf5\",\"cursor\":\"#d97757\"}" \
        /usr/local/bin/gemini-loop ${debug_flag}
}

# Setup ha-mcp
setup_ha_mcp() {
    if [ -f "/opt/scripts/setup-ha-mcp.sh" ]; then
        chmod +x /opt/scripts/setup-ha-mcp.sh
        [ -n "$GEMINI_API_KEY" ] && export GEMINI_API_KEY="$GEMINI_API_KEY"
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
