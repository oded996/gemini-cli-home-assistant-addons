#!/bin/bash

# Gemini Session Picker - Interactive menu for choosing Gemini session type
# Provides options for new session, continue, resume, manual command, or regular shell

show_banner() {
    clear
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🤖 Antigravity CLI                        ║"
    echo "║                   Interactive Session Picker                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

show_menu() {
    echo "Choose your Gemini session type:"
    echo ""
    echo "  1) 🆕 New interactive session (default)"
    echo "  2) ⏩ Continue most recent conversation (-c)"
    echo "  3) 📋 Resume from conversation list (-r)" 
    echo "  4) ⚙️  Custom Gemini command (manual flags)"
    echo "  5) 🐚 Drop to bash shell"
    echo "  6) ❌ Exit"
    echo ""
}

get_user_choice() {
    local choice
    echo -n "Enter your choice [1-6] (default: 1): "
    read -r choice
    
    # Default to 1 if empty
    if [ -z "$choice" ]; then
        choice=1
    fi
    
    echo "$choice"
}

launch_gemini_new() {
    echo "🚀 Starting new session..."
    sleep 1
    exec agy
}

launch_gemini_continue() {
    echo "⏩ Continuing most recent conversation..."
    sleep 1
    exec agy -c
}

launch_gemini_resume() {
    echo "📋 Opening conversation list for selection..."
    sleep 1
    exec agy -r
}

launch_gemini_custom() {
    echo ""
    echo "Enter your command (e.g., 'agy --help' or 'agy -p \"hello\"'):"
    echo "Available flags: -c (continue), -r (resume), -p (print), --model, etc."
    echo -n "> agy "
    read -r custom_args
    
    if [ -z "$custom_args" ]; then
        echo "No arguments provided. Starting default session..."
        launch_gemini_new
    else
        echo "🚀 Running: agy $custom_args"
        sleep 1
        eval "exec agy $custom_args"
    fi
}

launch_bash_shell() {
    echo "🐚 Dropping to bash shell..."
    echo "Tip: Run 'agy' (or 'gemini') manually when ready, or 'gemini-logout' to clear credentials"
    sleep 1
    exec bash
}

save_credentials_and_exit() {
    echo "💾 Saving credentials before exit..."
    /usr/local/bin/credentials-manager save
    exit 0
}

# Main execution flow
main() {
    # Ensure credentials are managed
    /usr/local/bin/credentials-manager save > /dev/null 2>&1
    
    while true; do
        show_banner
        show_menu
        choice=$(get_user_choice)
        
        case "$choice" in
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
                launch_bash_shell
                ;;
            6)
                save_credentials_and_exit
                ;;
            *)
                echo ""
                echo "❌ Invalid choice: $choice"
                echo "Please select a number between 1-6"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
        esac
    done
}

# Handle cleanup on exit
trap 'save_credentials_and_exit' EXIT INT TERM

# Run main function
main "$@"