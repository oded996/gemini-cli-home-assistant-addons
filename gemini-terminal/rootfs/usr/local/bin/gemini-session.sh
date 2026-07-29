#!/usr/bin/env bash
# =============================================================================
# Gemini CLI Session - Wrapper script that runs inside ttyd
# =============================================================================

# Load user-defined environment variables (written by init-gemini)
if [ -f /data/.env_vars ]; then
    source /data/.env_vars
fi

# Ensure SUPERVISOR_TOKEN is available for MCP server
if [ -z "$SUPERVISOR_TOKEN" ]; then
    echo "Warning: SUPERVISOR_TOKEN not set. MCP integration may not work."
fi

# Change to Home Assistant config directory
cd /homeassistant

# Set up PATH - ensure agy and standard bins are available
export PATH="/usr/local/bin:/usr/bin:/bin:/root/.antigravity/bin:/data/.antigravity/bin:/root/.local/bin:/data/.local/bin:$PATH"

# Configure git if not already configured
if [ ! -f "${HOME}/.gitconfig" ]; then
    git config --global init.defaultBranch main 2>/dev/null || true
    git config --global safe.directory /homeassistant 2>/dev/null || true
fi

# KDE Breeze-style colors
BLUE='\033[38;2;29;153;243m'
GREEN='\033[38;2;17;209;22m'
YELLOW='\033[38;2;246;116;0m'
CYAN='\033[38;2;26;188;156m'
WHITE='\033[38;2;252;252;252m'
GRAY='\033[38;2;127;140;141m'
BOLD='\033[1m'
NC='\033[0m'

ADDON_VERSION=$(cat /data/.addon_version 2>/dev/null || echo "unknown")

# Function to show welcome banner
show_banner() {
    clear
    echo ""
    echo -e "${BLUE}${BOLD}Antigravity CLI${NC} ${GRAY}v${ADDON_VERSION}${NC}"
    echo -e "${GRAY}Terminal interface powered by Antigravity CLI (agy)${NC}"
    echo ""
    echo -e "${GRAY}────────────────────────────────────────────────────────────${NC}"
    echo ""
}

# Function to show shell help (after exiting agy)
show_shell_help() {
    echo ""
    echo -e "${GRAY}────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${WHITE}Dropped to shell.${NC} Working directory: ${CYAN}/homeassistant${NC}"
    echo ""
    echo -e "${BOLD}Commands${NC}"
    echo -e "  ${GREEN}agy${NC} (or ${GREEN}gemini${NC})  Restart the Antigravity coding agent"
    echo -e "  ${GREEN}ha-logs${NC} ${GRAY}<type>${NC}    View logs (core, error, supervisor, host)"
    echo -e "  ${GREEN}hab${NC} ${GRAY}<cmd>${NC}         HA admin CLI (entities, areas, dashboards, backups)"
    echo -e "  ${GREEN}zigporter${NC} ${GRAY}<cmd>${NC}   Zigbee tools (rename, inspect, stale, mesh)"
    echo ""
}

show_banner

echo -e "${WHITE}Working directory:${NC} ${CYAN}/homeassistant${NC}"
echo -e "${GRAY}Customize AI behavior by editing ${NC}${GREEN}AGENTS.md${NC} ${GRAY}in your config folder${NC}"
echo ""

# Launch Antigravity CLI (agy)
AGY_BIN=$(which agy 2>/dev/null || find /root /usr /data -name "agy" -type f 2>/dev/null | head -n 1 || echo "agy")
"$AGY_BIN"

# When agy exits, show help and drop to bash
show_shell_help

# Start interactive bash shell
exec bash --login
