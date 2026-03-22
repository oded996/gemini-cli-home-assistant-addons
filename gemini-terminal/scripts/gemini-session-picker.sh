#!/bin/bash

# Gemini Session Picker - Interactive menu for choosing Gemini session type
# Provides options for new session, continue, resume, manual command, or regular shell
# Now with tmux session persistence for reconnection on navigation

TMUX_SESSION_NAME="gemini"

# Colors
TERRACOTTA='\033[38;2;217;119;87m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

show_banner() {
    clear
    echo ""
    echo -e "  ${TERRACOTTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${TERRACOTTA}║${NC}                                                              ${TERRACOTTA}║${NC}"
    echo -e "  ${TERRACOTTA}║${NC}   ${WHITE}Gemini Terminal${NC}  ${DIM}·  Session Picker${NC}                         ${TERRACOTTA}║${NC}"
    echo -e "  ${TERRACOTTA}║${NC}                                                              ${TERRACOTTA}║${NC}"
    echo -e "  ${TERRACOTTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Check if a tmux session exists and is running
check_existing_session() {
    tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null
}

show_menu() {
    echo "Choose your Gemini session type:"
    echo ""

    # Show reconnect option if session exists
    if check_existing_session; then
        echo "  0) 🔄 Reconnect to existing session (recommended)"
        echo ""
    fi

    echo "  1) 🆕 New interactive session (default)"
    echo "  2) ⏩ Continue most recent conversation (-c)"
    echo "  3) 📋 Resume from conversation list (-r)"
    echo "  4) ⚙️  Custom Gemini command (manual flags)"
    echo "  5) 🔐 Authentication helper (if paste doesn't work)"
    echo "  6) 🐚 Drop to bash shell"
    echo "  7) ❌ Exit"
    echo ""
}

get_user_choice() {
    local choice
    local default="1"

    # Default to 0 (reconnect) if session exists
    if check_existing_session; then
        default="0"
    fi

    printf "Enter your choice [0-7] (default: %s): " "$default" >&2
    read -r choice
    

    # Use default if empty
    if [ -z "$choice" ]; then
        choice="$default"
    fi

    # Trim whitespace and return only the choice
    choice=$(echo "$choice" | tr -d '[:space:]')
    echo "$choice"
}

# Attach to existing tmux session
attach_existing_session() {
    echo "🔄 Reconnecting to existing Gemini session..."
    sleep 1
    exec tmux attach-session -t "$TMUX_SESSION_NAME"
}

# Start gemini in a new tmux session (kills existing if any)
launch_gemini_new() {
    echo "🚀 Starting new Gemini session..."

    # Kill existing session if present
    if check_existing_session; then
        echo "   (closing previous session)"
        tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null
    fi

    sleep 1
    exec tmux new-session -s "$TMUX_SESSION_NAME" 'gemini'
}

launch_gemini_continue() {
    echo "⏩ Continuing most recent conversation..."

    if check_existing_session; then
        tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null
    fi

    sleep 1
    exec tmux new-session -s "$TMUX_SESSION_NAME" 'gemini -r latest'
}

launch_gemini_resume() {
    echo "📋 Opening conversation list for selection..."

    if check_existing_session; then
        tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null
    fi

    sleep 1
    # First list sessions, then ask for index or just run with -r
    gemini --list-sessions
    echo ""
    echo -n "Enter session index to resume (or 'latest'): "
    read -r session_idx
    if [ -z "$session_idx" ]; then session_idx="latest"; fi
    
    exec tmux new-session -s "$TMUX_SESSION_NAME" "gemini -r $session_idx"
}

launch_gemini_custom() {
    echo ""
    echo "Enter your Gemini command (e.g., 'gemini --help' or 'gemini -p \"hello\"'):"
    echo "Available flags: -c (continue), -r (resume), -p (print), --model, etc."
    echo -n "> gemini "
    read -r custom_args

    if [ -z "$custom_args" ]; then
        echo "No arguments provided. Starting default session..."
        launch_gemini_new
    else
        echo "🚀 Running: gemini $custom_args"

        if check_existing_session; then
            tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null
        fi

        sleep 1
        exec tmux new-session -s "$TMUX_SESSION_NAME" "gemini $custom_args"
    fi
}

launch_auth_helper() {
    echo "🔐 Starting authentication helper..."
    sleep 1
    exec /opt/scripts/gemini-auth-helper.sh
}

launch_bash_shell() {
    echo "🐚 Dropping to bash shell..."
    echo "Tip: Run 'tmux new-session -A -s gemini \"gemini\"' to start with persistence"
    sleep 1
    exec bash
}

exit_session_picker() {
    echo "👋 Goodbye!"
    exit 0
}

# Main execution flow
main() {
    while true; do
        show_banner
        show_menu
        choice=$(get_user_choice)

        case "$choice" in
            0)
                if check_existing_session; then
                    attach_existing_session
                else
                    echo "❌ No existing session found"
                    sleep 1
                fi
                ;;
            1)
                launch_gemini_new
                ;;
            2)
                launch_gemini_continue
                ;;
            3)
                launch_gemini_resume
                ;;
            4)
                launch_gemini_custom
                ;;
            5)
                launch_auth_helper
                ;;
            6)
                launch_bash_shell
                ;;
            7)
                exit_session_picker
                ;;
            *)
                echo ""
                echo "❌ Invalid choice: '$choice'"
                echo "Please select a number between 0-7"
                echo ""
                printf "Press Enter to continue..." >&2
                read -r
                ;;
        esac
    done
}

# Handle cleanup on exit - don't kill tmux session, just exit picker
trap 'echo ""; exit 0' EXIT INT TERM

# Run main function
main "$@"
