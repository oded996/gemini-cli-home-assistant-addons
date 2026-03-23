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

    # Create the TTY-forcing launcher
    # We use 'script' to force a PTY (Pseudo-Terminal)
    # This is the industry-standard "PTY Hack"
    cat > /usr/local/bin/gemini-pty << 'EOF'
#!/bin/bash
export TERM=xterm-256color
# Force a pseudo-terminal for Node.js
# -q: quiet, -c: command, -e: return exit code, /dev/null: no typescript file
script -q -e -c "/usr/local/bin/gemini --sandbox false --acp false --raw-output --accept-raw-output-risk $@" /dev/null
EOF
    chmod +x /usr/local/bin/gemini-pty

    # Get user configuration
    local gemini_debug=$(bashio::config 'gemini_debug' 'false')
    local debug_flag=""
    [ "$gemini_debug" = "true" ] && debug_flag="--debug"

    # Run ttyd: we run gemini-pty DIRECTLY to preserve the TTY link
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 2 \
        --client-option enableReconnect=true \
        --client-option copyOnSelect=true \
        --client-option "theme={\"background\":\"#1a1b26\",\"foreground\":\"#c0caf5\",\"cursor\":\"#d97757\"}" \
        /usr/local/bin/gemini-pty ${debug_flag}
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
