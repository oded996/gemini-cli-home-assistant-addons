#!/usr/bin/with-contenv bashio
# Setup ha-mcp (Home Assistant MCP Server) for Gemini Code
# This script configures Gemini Code to use ha-mcp for Home Assistant integration
# Repository: https://github.com/homeassistant-ai/ha-mcp

set -e

# Check if ha-mcp setup should be enabled
configure_ha_mcp_server() {
    local enable_ha_mcp
    enable_ha_mcp=$(bashio::config 'enable_ha_mcp' 'true')

    if [ "$enable_ha_mcp" != "true" ]; then
        bashio::log.info "ha-mcp integration is disabled in configuration"
        return 0
    fi

    bashio::log.info "Setting up ha-mcp (Home Assistant MCP Server)..."

    # Check for supervisor token (required for HA API access)
    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        bashio::log.warning "SUPERVISOR_TOKEN not available - ha-mcp setup skipped"
        bashio::log.warning "MCP server requires Supervisor API access"
        return 0
    fi

    # Check if uv/uvx is available
    if ! command -v uvx &> /dev/null; then
        bashio::log.warning "uvx not found - ha-mcp setup skipped"
        return 0
    fi

    # Configure Gemini Code to use ha-mcp
    # The MCP server will connect to Home Assistant via the Supervisor API
    bashio::log.info "Configuring Gemini Code MCP server for Home Assistant..."

    # Define settings path (respecting HOME set in run.sh)
    local gemini_user_dir="${HOME}/.gemini"
    local settings_file="${gemini_user_dir}/settings.json"
    
    mkdir -p "$gemini_user_dir"

    # Initialize settings.json if it doesn't exist
    if [ ! -f "$settings_file" ]; then
        echo '{"mcpServers": {}}' > "$settings_file"
    fi

    # Ensure mcpServers object exists
    if ! jq -e '.mcpServers' "$settings_file" >/dev/null 2>&1; then
        jq '. + {"mcpServers": {}}' "$settings_file" > "${settings_file}.tmp" && mv "${settings_file}.tmp" "$settings_file"
    fi

    # Determine the command to use (prefer pre-installed ha-mcp)
    local mcp_command="ha-mcp"
    if ! command -v ha-mcp &> /dev/null; then
        if command -v uvx &> /dev/null; then
            mcp_command="uvx ha-mcp"
        else
            bashio::log.warning "Neither ha-mcp nor uvx found - MCP might not work"
        fi
    fi

    # Add/Update the home-assistant MCP server configuration using jq
    # This bypasses the 'gemini mcp add' command which requires an API key to run
    bashio::log.info "Updating MCP configuration in $settings_file"
    
    if jq --arg command "$mcp_command" --arg token "$SUPERVISOR_TOKEN" '.mcpServers["home-assistant"] = {
        "command": ($command | split(" ")[0]),
        "args": ($command | split(" ")[1:]),
        "env": {
            "HOMEASSISTANT_URL": "http://supervisor/core",
            "HOMEASSISTANT_TOKEN": $token,
            "HASS_URL": "http://supervisor/core",
            "HASS_TOKEN": $token
        }
    }' "$settings_file" > "${settings_file}.tmp" && mv "${settings_file}.tmp" "$settings_file"; then
        bashio::log.info "ha-mcp configured successfully via jq!"
        bashio::log.info "Gemini Code will have access to Home Assistant via MCP once started"
    else
        bashio::log.warning "Failed to configure ha-mcp using jq - attempting legacy method"
        
        # Fallback to gemini mcp add (might fail if no API key is set)
        if gemini mcp add home-assistant \
            --env "HOMEASSISTANT_URL=http://supervisor/core" \
            --env "HOMEASSISTANT_TOKEN=${SUPERVISOR_TOKEN}" \
            --env "HASS_URL=http://supervisor/core" \
            --env "HASS_TOKEN=${SUPERVISOR_TOKEN}" \
            ha-mcp; then
            bashio::log.info "ha-mcp configured successfully via CLI!"
        else
            bashio::log.warning "Failed to configure ha-mcp - continuing without MCP integration"
            bashio::log.warning "You can manually run: gemini mcp add home-assistant --env HOMEASSISTANT_URL=http://supervisor/core --env HOMEASSISTANT_TOKEN=\$SUPERVISOR_TOKEN -- ha-mcp"
        fi
    fi
}

# Run setup if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_ha_mcp_server
fi
