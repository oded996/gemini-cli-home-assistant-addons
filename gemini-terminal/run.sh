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
            bashio::log.info "Gemini API key configured from add-on options (masking: ${api_key:0:4}...${api_key: -4})"
        else
            bashio::log.info "Gemini API key option is empty or null"
        fi
    else
        bashio::log.info "Gemini API key not found in configuration"
    fi

    # Migrate any existing authentication files from legacy locations
    migrate_legacy_auth_files "$gemini_config_dir"

    # Install tmux configuration to user home directory
    if [ -f "/opt/scripts/tmux.conf" ]; then
        cp /opt/scripts/tmux.conf "$data_home/.tmux.conf"
        chmod 644 "$data_home/.tmux.conf"
        bashio::log.info "tmux configuration installed to $data_home/.tmux.conf"
    fi

    # Ensure .geminiignore exists to prevent massive scans of HA database/backups
    if [ ! -f "/config/.geminiignore" ]; then
        bashio::log.info "Creating default /config/.geminiignore to skip large files..."
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

    # Create symlink to internal logs for easy access via File Editor
    mkdir -p "$data_home/.gemini/logs"
    ln -sf "$data_home/.gemini/logs" "/config/gemini-logs"

    bashio::log.info "Environment initialized:"
    bashio::log.info "  - Home: $HOME"
    bashio::log.info "  - Config: $XDG_CONFIG_HOME"
    bashio::log.info "  - Gemini config: $GEMINI_CONFIG_DIR"
    bashio::log.info "  - Cache: $XDG_CACHE_HOME"
}

# One-time migration of existing authentication files
migrate_legacy_auth_files() {
    local target_dir="$1"
    local migrated=false

    bashio::log.info "Checking for existing authentication files to migrate..."

    # Check common legacy locations
    local legacy_locations=(
        "/root/.config/google"
        "/root/.google" 
        "/config/gemini-config"
        "/tmp/gemini-config"
    )

    for legacy_path in "${legacy_locations[@]}"; do
        if [ -d "$legacy_path" ] && [ "$(ls -A "$legacy_path" 2>/dev/null)" ]; then
            bashio::log.info "Migrating auth files from: $legacy_path"
            
            # Copy files to new location
            if cp -r "$legacy_path"/* "$target_dir/" 2>/dev/null; then
                # Set proper permissions
                find "$target_dir" -type f -exec chmod 600 {} \;
                
                # Create compatibility symlink if this is a standard location
                if [[ "$legacy_path" == "/root/.config/google" ]] || [[ "$legacy_path" == "/root/.google" ]]; then
                    rm -rf "$legacy_path"
                    ln -sf "$target_dir" "$legacy_path"
                    bashio::log.info "Created compatibility symlink: $legacy_path -> $target_dir"
                fi
                
                migrated=true
                bashio::log.info "Migration completed from: $legacy_path"
            else
                bashio::log.warning "Failed to migrate from: $legacy_path"
            fi
        fi
    done

    if [ "$migrated" = false ]; then
        bashio::log.info "No existing authentication files found to migrate"
    fi
}

# Install required tools
install_tools() {
    bashio::log.info "Installing additional tools..."
    if ! apk add --no-cache ttyd jq curl tmux; then
        bashio::log.error "Failed to install required tools"
        exit 1
    fi
    bashio::log.info "Tools installed successfully"
}

# Install persistent packages from config and saved state
install_persistent_packages() {
    bashio::log.info "Checking for persistent packages..."

    local persist_config="/data/persistent-packages.json"
    local apk_packages=""
    local pip_packages=""

    # Collect APK packages from Home Assistant config
    if bashio::config.has_value 'persistent_apk_packages'; then
        local config_apk
        config_apk=$(bashio::config 'persistent_apk_packages')
        if [ -n "$config_apk" ] && [ "$config_apk" != "null" ]; then
            apk_packages="$config_apk"
            bashio::log.info "Found APK packages in config: $apk_packages"
        fi
    fi

    # Collect pip packages from Home Assistant config
    if bashio::config.has_value 'persistent_pip_packages'; then
        local config_pip
        config_pip=$(bashio::config 'persistent_pip_packages')
        if [ -n "$config_pip" ] && [ "$config_pip" != "null" ]; then
            pip_packages="$config_pip"
            bashio::log.info "Found pip packages in config: $pip_packages"
        fi
    fi

    # Also check local persist-install config file
    if [ -f "$persist_config" ]; then
        bashio::log.info "Found local persistent packages config"

        # Get APK packages from local config
        local local_apk
        local_apk=$(jq -r '.apk_packages | join(" ")' "$persist_config" 2>/dev/null || echo "")
        if [ -n "$local_apk" ]; then
            apk_packages="$apk_packages $local_apk"
        fi

        # Get pip packages from local config
        local local_pip
        local_pip=$(jq -r '.pip_packages | join(" ")' "$persist_config" 2>/dev/null || echo "")
        if [ -n "$local_pip" ]; then
            pip_packages="$pip_packages $local_pip"
        fi
    fi

    # Trim whitespace and remove duplicates
    apk_packages=$(echo "$apk_packages" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)
    pip_packages=$(echo "$pip_packages" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)

    # Install APK packages
    if [ -n "$apk_packages" ]; then
        bashio::log.info "Installing persistent APK packages: $apk_packages"
        # shellcheck disable=SC2086
        if apk add --no-cache $apk_packages; then
            bashio::log.info "APK packages installed successfully"
        else
            bashio::log.warning "Some APK packages failed to install"
        fi
    fi

    # Install pip packages
    if [ -n "$pip_packages" ]; then
        bashio::log.info "Installing persistent pip packages: $pip_packages"
        # shellcheck disable=SC2086
        if pip3 install --break-system-packages --no-cache-dir $pip_packages; then
            bashio::log.info "pip packages installed successfully"
        else
            bashio::log.warning "Some pip packages failed to install"
        fi
    fi

    if [ -z "$apk_packages" ] && [ -z "$pip_packages" ]; then
        bashio::log.info "No persistent packages configured"
    fi
}

# Setup session picker script
setup_session_picker() {
    # Copy session picker script from built-in location
    if [ -f "/opt/scripts/gemini-session-picker.sh" ]; then
        if ! cp /opt/scripts/gemini-session-picker.sh /usr/local/bin/gemini-session-picker; then
            bashio::log.error "Failed to copy gemini-session-picker script"
            exit 1
        fi
        chmod +x /usr/local/bin/gemini-session-picker
        bashio::log.info "Session picker script installed successfully"
    else
        bashio::log.warning "Session picker script not found, using auto-launch mode only"
    fi

    # Setup authentication helper if it exists
    if [ -f "/opt/scripts/gemini-auth-helper.sh" ]; then
        chmod +x /opt/scripts/gemini-auth-helper.sh
        bashio::log.info "Authentication helper script ready"
    fi

    # Setup persist-install script if it exists
    if [ -f "/opt/scripts/persist-install.sh" ]; then
        if ! cp /opt/scripts/persist-install.sh /usr/local/bin/persist-install; then
            bashio::log.warning "Failed to copy persist-install script"
        else
            chmod +x /usr/local/bin/persist-install
            bashio::log.info "Persist-install script installed successfully"
        fi
    fi

    # Setup welcome script
    if [ -f "/opt/scripts/welcome.sh" ]; then
        if cp /opt/scripts/welcome.sh /usr/local/bin/welcome; then
            chmod +x /usr/local/bin/welcome
            bashio::log.info "Welcome script installed successfully"
        else
            bashio::log.warning "Failed to copy welcome script"
        fi
    fi

    # Setup ha-context script
    if [ -f "/opt/scripts/ha-context.sh" ]; then
        if cp /opt/scripts/ha-context.sh /usr/local/bin/ha-context; then
            chmod +x /usr/local/bin/ha-context
            bashio::log.info "HA context script installed successfully"
        else
            bashio::log.warning "Failed to copy ha-context script"
        fi
    fi

    # Write add-on version for welcome script to read (avoids bashio dependency in ttyd)
    bashio::addon.version > /opt/scripts/addon-version 2>/dev/null || echo "unknown" > /opt/scripts/addon-version
}

# Legacy monitoring functions removed - using simplified /data approach

# Generate Home Assistant context file for Gemini sessions
generate_ha_context() {
    local ha_smart_context
    ha_smart_context=$(bashio::config 'ha_smart_context' 'true')

    if [ "$ha_smart_context" = "true" ]; then
        bashio::log.info "Generating Home Assistant context for Gemini sessions..."
        if [ -f /usr/local/bin/ha-context ]; then
            if /usr/local/bin/ha-context 2>&1 | while IFS= read -r line; do
                bashio::log.info "$line"
            done; then
                bashio::log.info "HA context generated successfully"
            else
                bashio::log.warning "HA context generation had issues, continuing..."
            fi
        else
            bashio::log.warning "ha-context script not found, skipping"
        fi
    else
        bashio::log.info "HA Smart Context disabled in configuration"
    fi
}

# Determine Gemini launch command based on configuration
get_gemini_launch_command() {
    local auto_launch_gemini
    local gemini_debug
    local debug_flag=""
    local cmd

    # Get configuration values
    auto_launch_gemini=$(bashio::config 'auto_launch_gemini' 'true')
    gemini_debug=$(bashio::config 'gemini_debug' 'false')

    if [ "$gemini_debug" = "true" ]; then
        debug_flag="--debug"
    fi

    # Loading message to show while tmux/gemini starts
    local loading_msg="echo -e '\033[0;36mInitializing Gemini Terminal...\033[0m'; "

    if [ "$auto_launch_gemini" = "true" ]; then
        # Use tmux for session persistence
        cmd="tmux -u new-session -A -s gemini \"gemini ${debug_flag}\""
    else
        if [ -f /usr/local/bin/gemini-session-picker ]; then
            cmd="/usr/local/bin/gemini-session-picker"
        else
            bashio::log.warning "Session picker not found, falling back to auto-launch"
            cmd="tmux -u new-session -A -s gemini \"gemini ${debug_flag}\""
        fi
    fi

    # Final command string: show loading, run main command, then fallback to bash
    echo "${loading_msg}${cmd}; echo ''; echo 'Terminal session ended. Dropping to bash...'; exec bash"
}


# Start main web terminal
start_web_terminal() {
    local port=7682
    bashio::log.info "Starting web terminal on port ${port}..."
    
    # Log environment information for debugging
    bashio::log.info "Environment variables:"
    bashio::log.info "GEMINI_CONFIG_DIR=${GEMINI_CONFIG_DIR}"
    bashio::log.info "HOME=${HOME}"

    # Get the appropriate launch command based on configuration
    local launch_command
    launch_command=$(get_gemini_launch_command)
    
    # Log the configuration being used
    local auto_launch_gemini
    auto_launch_gemini=$(bashio::config 'auto_launch_gemini' 'true')
    bashio::log.info "Auto-launch Gemini: ${auto_launch_gemini}"
    
    # Set TTYD environment variable for tmux configuration
    # This disables tmux mouse mode since ttyd has better mouse handling for web terminals
    export TTYD=1

    # Terminal theme - dark palette with terracotta accents (#d97757)
    local ttyd_theme='{"background":"#1a1b26","foreground":"#c0caf5","cursor":"#d97757","cursorAccent":"#1a1b26","selectionBackground":"#33467c","selectionForeground":"#c0caf5","black":"#15161e","red":"#f7768e","green":"#9ece6a","yellow":"#e0af68","blue":"#7aa2f7","magenta":"#bb9af7","cyan":"#7dcfff","white":"#a9b1d6","brightBlack":"#414868","brightRed":"#f7768e","brightGreen":"#9ece6a","brightYellow":"#e0af68","brightBlue":"#7aa2f7","brightMagenta":"#bb9af7","brightCyan":"#7dcfff","brightWhite":"#c0caf5"}'

    # Run ttyd with aggressive keepalive configuration
    # See: https://github.com/tsl0922/ttyd/issues/1000
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 5 \
        --client-option enableReconnect=true \
        --client-option reconnect=10 \
        --client-option reconnectInterval=5 \
        --client-option "theme=${ttyd_theme}" \
        --client-option fontSize=14 \
        bash -c "$launch_command"
}

# Run health check
run_health_check() {
    if [ -f "/opt/scripts/health-check.sh" ]; then
        bashio::log.info "Running system health check..."
        chmod +x /opt/scripts/health-check.sh
        /opt/scripts/health-check.sh || bashio::log.warning "Some health checks failed but continuing..."
    fi
}

# Setup ha-mcp (Home Assistant MCP Server) for Gemini CLI integration
setup_ha_mcp() {
    if [ -f "/opt/scripts/setup-ha-mcp.sh" ]; then
        bashio::log.info "Setting up Home Assistant MCP integration..."
        chmod +x /opt/scripts/setup-ha-mcp.sh
        # Source the script to get the configure function
        source /opt/scripts/setup-ha-mcp.sh
        configure_ha_mcp_server || bashio::log.warning "ha-mcp setup encountered issues but continuing..."
    else
        bashio::log.info "ha-mcp setup script not found, skipping MCP integration"
    fi
}

# Tail Gemini logs to add-on logs if debug is enabled
tail_gemini_logs() {
    local gemini_debug
    gemini_debug=$(bashio::config 'gemini_debug' 'false')

    if [ "$gemini_debug" = "true" ]; then
        bashio::log.info "Gemini debug enabled. Tailing internal logs..."
        # Try common log locations
        local log_dirs=(
            "$HOME/.gemini/logs"
            "$GEMINI_CONFIG_DIR/logs"
        )
        
        for log_dir in "${log_dirs[@]}"; do
            mkdir -p "$log_dir"
            # Watch for new files in log_dir and tail them
            (
                while true; do
                    local latest_log=$(ls -t "$log_dir"/*.log 2>/dev/null | head -n 1)
                    if [ -n "$latest_log" ]; then
                        bashio::log.info "Tailing latest log: $latest_log"
                        tail -f "$latest_log" | while read -r line; do
                            echo "[Gemini Debug] $line"
                        done
                    fi
                    sleep 5
                done
            ) &
        done
    fi
}

# Main execution
main() {
    bashio::log.info "Initializing Gemini Terminal add-on..."

    # Run diagnostics first (especially helpful for VirtualBox issues)
    run_health_check

    # Log command availability
    if command -v gemini > /dev/null; then
        bashio::log.info "Gemini command found at: $(which gemini)"
    else
        bashio::log.error "Gemini command NOT FOUND in PATH ($PATH)"
    fi

    init_environment
    install_tools
    setup_session_picker
    install_persistent_packages
    generate_ha_context
    setup_ha_mcp
    tail_gemini_logs
    start_web_terminal
}

# Execute main function
main "$@"
