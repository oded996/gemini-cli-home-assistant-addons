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

    bashio::log.info "Initializing Gemini CLI environment in /data..."

    # Create all required directories
    if ! mkdir -p "$data_home" "$config_dir/gemini" "$cache_dir" "$state_dir" "/data/.local"; then
        bashio::log.error "Failed to create directories in /data"
        exit 1
    fi

    # Set permissions
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
    
    # Critical for Node.js stability in containers
    export NODE_OPTIONS="--max-old-space-size=4096"
    export PYTHONUNBUFFERED=1

    # Set Gemini API key if provided in configuration
    if bashio::config.has_value 'gemini_api_key'; then
        local api_key
        api_key=$(bashio::config 'gemini_api_key')
        if [ -n "$api_key" ] && [ "$api_key" != "null" ]; then
            export GOOGLE_API_KEY="$api_key"
            export GEMINI_API_KEY="$api_key"
            bashio::log.info "Gemini API key configured from add-on options"
        fi
    fi

    # Migrate any existing authentication files from legacy locations
    migrate_legacy_auth_files "$gemini_config_dir"

    # Install tmux configuration to user home directory
    if [ -f "/opt/scripts/tmux.conf" ]; then
        cp /opt/scripts/tmux.conf "$data_home/.tmux.conf"
        chmod 644 "$data_home/.tmux.conf"
    fi

    # Ensure .geminiignore exists to prevent massive scans
    if [ ! -f "/config/.geminiignore" ]; then
        bashio::log.info "Creating default /config/.geminiignore..."
        cat > "/config/.geminiignore" << 'EOF'
.storage/
backups/
addons/
*.db
*.db-shm
*.db-wal
*.log
EOF
    fi

    # Log system limits and state
    {
        echo "--- Session Start: $(date) ---"
        echo "Node: $(node --version)"
        [ -f /proc/sys/fs/inotify/max_user_watches ] && echo "Inotify limit: $(cat /proc/sys/fs/inotify/max_user_watches)"
        free -m
    } > /config/gemini_system.log

    bashio::log.info "Environment initialized:"
    bashio::log.info "  - Home: $HOME"
    bashio::log.info "  - Config: $XDG_CONFIG_HOME"
    bashio::log.info "  - Gemini config: $GEMINI_CONFIG_DIR"
}

# One-time migration of existing authentication files
migrate_legacy_auth_files() {
    local target_dir="$1"
    local migrated=false
    local legacy_locations=("/root/.config/google" "/root/.google" "/config/gemini-config" "/tmp/gemini-config")
    for legacy_path in "${legacy_locations[@]}"; do
        if [ -d "$legacy_path" ] && [ "$(ls -A "$legacy_path" 2>/dev/null)" ]; then
            cp -r "$legacy_path"/* "$target_dir/" 2>/dev/null || true
            migrated=true
        fi
    done
}

# Install required tools
install_tools() {
    bashio::log.info "Installing additional tools..."
    if ! apk add --no-cache ttyd jq curl tmux coreutils; then
        bashio::log.error "Failed to install required tools"
        exit 1
    fi
}

# Start main web terminal
start_web_terminal() {
    local port=7682
    bashio::log.info "Starting web terminal on port ${port}..."

    local launch_command
    local auto_launch_gemini=$(bashio::config 'auto_launch_gemini' 'true')
    local gemini_debug=$(bashio::config 'gemini_debug' 'false')
    local debug_flag=""
    [ "$gemini_debug" = "true" ] && debug_flag="--debug"

    if [ "$auto_launch_gemini" = "true" ]; then
        launch_command="tmux -u new-session -A -s gemini \"gemini ${debug_flag} --sandbox false\""
    else
        if [ -f /usr/local/bin/gemini-session-picker ]; then
            launch_command="/usr/local/bin/gemini-session-picker"
        else
            launch_command="tmux -u new-session -A -s gemini \"gemini ${debug_flag} --sandbox false\""
        fi
    fi

    # Start a background process to mirror internal logs to /config/gemini-logs
    # This avoids the "Access Denied" symlink issues and boot failures
    (
        local src="/data/home/.gemini/logs"
        local dest="/config/gemini-logs"
        mkdir -p "$dest"
        while true; do
            if [ -d "$src" ]; then
                cp -r "$src"/* "$dest/" 2>/dev/null || true
                chmod 666 "$dest"/* 2>/dev/null || true
            fi
            sleep 10
        done
    ) &

    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 5 \
        --client-option "theme={\"background\":\"#1a1b26\",\"foreground\":\"#c0caf5\",\"cursor\":\"#d97757\"}" \
        bash -c "echo -e '\033[0;36mInitializing Gemini Terminal...\033[0m'; ${launch_command}; echo ''; echo 'Gemini session ended. Dropping to bash...'; exec bash"
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
    bashio::log.info "Initializing Gemini Terminal add-on..."
    init_environment
    install_tools
    setup_ha_mcp
    start_web_terminal
}

main "$@"
