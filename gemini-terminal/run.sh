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
    
    # Restore standard interactive settings
    cat > "$gemini_user_dir/settings.json" << 'EOF'
{
  "approvalMode": "default",
  "screenReader": false,
  "telemetry": "off"
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

    local node_bin=$(which node)
    local gemini_bin=$(which gemini)
    
    # Internal trace capture script
    cat > /usr/local/bin/gemini-wrapper << 'EOF'
#!/bin/bash
# Run Gemini and capture the internal trace on exit
/usr/bin/node /usr/local/bin/gemini --sandbox false --acp false --raw-output --accept-raw-output-risk "$@"
EXIT_CODE=$?
echo ""
echo "------------------------------------------------"
echo "Gemini session finished with Exit Code: $EXIT_CODE"
echo "Attempting to extract internal diagnostic trace..."
LATEST_LOG=$(ls -t /data/home/.gemini/logs/*.log 2>/dev/null | head -n 1)
if [ -n "$LATEST_LOG" ]; then
    cp "$LATEST_LOG" /config/gemini_internal_trace.log
    echo "Internal trace saved to: /config/gemini_internal_trace.log"
    echo "Last 10 lines of trace:"
    tail -n 10 /config/gemini_internal_trace.log
else
    echo "No internal Gemini logs were found."
fi
echo "------------------------------------------------"
EOF
    chmod +x /usr/local/bin/gemini-wrapper

    # Run ttyd with an extremely fast heartbeat and fixed terminal size
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 2 \
        --ping-timeout 60 \
        --client-option enableReconnect=true \
        --client-option copyOnSelect=true \
        --client-option "theme={\"background\":\"#1a1b26\",\"foreground\":\"#c0caf5\",\"cursor\":\"#d97757\"}" \
        bash -c "echo -e '\033[0;36mInitializing Gemini CLI...\033[0m'; gemini-wrapper; echo ''; echo 'Gemini session ended.'; exec bash"
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
