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
    
    # Fix settings.json - removed all invalid keys
    cat > "$gemini_user_dir/settings.json" << 'EOF'
{
  "approvalMode": "default"
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
            bashio::log.info "Gemini API key configured"
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
    
    # Improved trace capture script
    cat > /usr/local/bin/gemini-wrapper << 'EOF'
#!/bin/bash
# Run Gemini with fixed memory stack and capture trace
/usr/bin/node --stack-size=10000 --report-on-fatalerror --report-directory=/config /usr/local/bin/gemini --sandbox false --acp false --raw-output --accept-raw-output-risk "$@"
EXIT_CODE=$?
echo ""
echo "------------------------------------------------"
echo "Gemini session finished with Exit Code: $EXIT_CODE"
echo "Searching for internal diagnostic logs..."
# Search globally within the data directory for any .log files created by gemini
INTERNAL_LOG=$(find /data -name "*.log" -path "*/.gemini/logs/*" -type f -mmin -5 | head -n 1)
if [ -n "$INTERNAL_LOG" ]; then
    cp "$INTERNAL_LOG" /config/gemini_internal_trace.log
    echo "Internal trace extracted to: /config/gemini_internal_trace.log"
    echo "--- TRACE END ---"
    tail -n 20 /config/gemini_internal_trace.log
else
    echo "No internal logs were found in the last 5 minutes."
fi
echo "------------------------------------------------"
EOF
    chmod +x /usr/local/bin/gemini-wrapper

    # Get user configuration
    local gemini_debug=$(bashio::config 'gemini_debug' 'false')
    local debug_flag=""
    [ "$gemini_debug" = "true" ] && debug_flag="--debug"

    # Run ttyd
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 5 \
        --client-option enableReconnect=true \
        --client-option copyOnSelect=true \
        --client-option "theme={\"background\":\"#1a1b26\",\"foreground\":\"#c0caf5\",\"cursor\":\"#d97757\"}" \
        bash -c "echo -e '\033[0;36mInitializing Gemini CLI...\033[0m'; gemini-wrapper ${debug_flag}; echo ''; echo 'Gemini session ended.'; exec bash"
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
