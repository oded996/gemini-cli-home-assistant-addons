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
    
    # Force stable settings - removed invalid 'autocomplete' key
    cat > "$gemini_user_dir/settings.json" << 'EOF'
{
  "approvalMode": "yolo",
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

    # CRITICAL: Prepare the Crash Witness log and ensure it is IGNORED by Gemini
    local crash_log="/config/gemini_crash.log"
    touch "$crash_log"
    chmod 666 "$crash_log"

    # Force strict ignore rules
    cat > "/config/.geminiignore" << 'EOF'
.storage/
.git/
.gemini*/
gemini_crash.log
gemini_debug.log
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
}

# Start web terminal
start_web_terminal() {
    local port=7682
    bashio::log.info "Starting Gemini Terminal on port ${port}..."

    local node_bin=$(which node)
    local gemini_bin=$(which gemini)
    local crash_log="/config/gemini_crash.log"

    # Create a dedicated wrapper script
    # Removed invalid --no-autocomplete and updated --experimental-acp to --acp
    cat > /usr/local/bin/gemini-witness << EOF
#!/bin/bash
echo "--- NEW SESSION: \$(date) ---" >> ${crash_log}
${node_bin} --stack-size=10000 --report-on-fatalerror --report-directory=/config ${gemini_bin} --sandbox false --acp false --approval-mode yolo --raw-output --accept-raw-output-risk "\$@" 2>&1 | tee -a ${crash_log}
echo "--- SESSION ENDED: Code \$? AT \$(date) ---" >> ${crash_log}
EOF
    chmod +x /usr/local/bin/gemini-witness

    tmux kill-session -t gemini 2>/dev/null || true

    bashio::log.info "Launching Gemini under Witness mode..."
    tmux new-session -d -s gemini "tmux set-option -g mouse off; tmux set-option -g history-limit 50000; export TERM=xterm-256color; gemini-witness; echo ''; echo 'Gemini died. Check /config/gemini_crash.log'; exec bash"

    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 10 \
        --client-option enableReconnect=true \
        --client-option copyOnSelect=true \
        --client-option allowContextMenu=true \
        --client-option "theme={\"background\":\"#1a1b26\",\"foreground\":\"#c0caf5\",\"cursor\":\"#d97757\"}" \
        bash -c "echo -e '\033[0;36mConnecting to witness session...\033[0m'; sleep 1; tmux attach-session -t gemini"
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
