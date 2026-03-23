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
    export TERM="xterm"
    
    # Gemini Variables
    export GEMINI_CONFIG_DIR="$gemini_config_dir"
    export GEMINI_HOME="/data"
    export GEMINI_TELEMETRY=off
    # Tell Gemini it's already in the "relaunched" process so it runs the UI
    # directly without spawning a child. This also prevents auto-updates inside
    # the container (desired behaviour - updates come from image rebuilds).
    export GEMINI_CLI_NO_RELAUNCH=1
    
    # Restore standard interactive settings
    cat > "$gemini_user_dir/settings.json" << 'EOF'
{
  "approvalMode": "default",
  "screenReader": false,
  "acp": false,
  "sandbox": false
}
EOF

    # Trust /config and / so the Shell tool is allowed to execute commands
    cat > "$gemini_user_dir/trustedFolders.json" << 'EOF'
{
  "/config": "TRUST_FOLDER",
  "/": "TRUST_FOLDER",
  "/data": "TRUST_FOLDER",
  "/opt": "TRUST_FOLDER"
}
EOF

    # Node Stability
    export NODE_OPTIONS="--max-old-space-size=8192"
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

    # Create a direct-execution wrapper (no tmux, no script)
    cat > /usr/local/bin/gemini-direct << 'EOF'
#!/bin/bash
echo -e "\033[0;36mInitializing Gemini CLI (Direct TTY Mode)...\033[0m"
# Redirect stderr to a log file for crash diagnostics (UI uses stdout, so this is safe)
# We use --no-acp to properly disable background indexing
# We pass the memory flags directly to node for maximum stability
/usr/bin/node --max-old-space-size=8192 --stack-size=10000 /usr/local/bin/gemini --no-acp "$@" 2>/config/gemini_stderr.log
EXIT_CODE=$?
echo ""
echo "------------------------------------------------"
echo "Gemini process ended with Exit Code: $EXIT_CODE"
# Copy internal trace log if available
LATEST_LOG=$(find /data -name "*.log" -path "*/.gemini/logs/*" -type f -mmin -2 | head -n 1)
[ -n "$LATEST_LOG" ] && cp "$LATEST_LOG" /config/gemini_internal_trace.log
echo "Crash logs:"
echo "  stderr : /config/gemini_stderr.log"
echo "  trace  : /config/gemini_internal_trace.log"
echo "Run: cat /config/gemini_stderr.log"
echo "------------------------------------------------"
exec bash
EOF
    chmod +x /usr/local/bin/gemini-direct

    # Run ttyd: 
    # 1. ping-interval=1 keeps the proxy alive during long tasks
    # 2. No tmux means native browser selection (COPY/PASTE) works
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 1 \
        --client-option enableReconnect=true \
        --client-option copyOnSelect=true \
        --client-option "theme={\"background\":\"#1a1b26\",\"foreground\":\"#c0caf5\",\"cursor\":\"#d97757\"}" \
        /usr/local/bin/gemini-direct
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
