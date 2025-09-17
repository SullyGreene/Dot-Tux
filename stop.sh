#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# Dot-Tux Stop Script
#
# This script gracefully stops the Nginx server, the Python control panel,
# and releases the Termux wakelock.
# ==============================================================================

# --- Color Definitions for pretty printing ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_RED='\033[0;31m'
C_YELLOW='\033[1;33m'

# --- Helper Functions ---
print_info() {
    echo -e "${C_BLUE}[INFO] $1${C_RESET}"
}

print_success() {
    echo -e "${C_GREEN}[SUCCESS] $1${C_RESET}"
}

print_warning() {
    echo -e "${C_YELLOW}[WARNING] $1${C_RESET}"
}


# --- Main Stop Logic ---
clear
echo -e "${C_YELLOW}Stopping Dot-Tux Server...${C_RESET}"
echo ""

# --- Step 1: Stop the Python Control Panel ---
print_info "Stopping the Dot-Tux control panel (app.py)..."
# Use pkill to find and kill the specific python process.
if pgrep -f "python app.py" > /dev/null
then
    pkill -f "python app.py"
    print_success "Control panel stopped."
else
    print_warning "Control panel was not running."
fi
echo ""
sleep 1

# --- Step 2: Stop Nginx Server ---
print_info "Stopping Nginx web server..."
# Check if the process is running before trying to stop it.
if pgrep -x "nginx" > /dev/null
then
    # The 'nginx -s stop' command is a graceful shutdown.
    nginx -s stop
    print_success "Nginx stopped."
else
    print_warning "Nginx was not running."
fi
echo ""
sleep 1

# --- Step 3: Release Termux Wakelock ---
print_info "Releasing Termux wakelock..."
termux-wake-unlock
print_success "Wakelock released. Termux may now sleep."
echo ""

# --- Final Message ---
echo -e "${C_GREEN}############################################${C_RESET}"
echo -e "${C_GREEN}#                                          #${C_RESET}"
echo -e "${C_GREEN}#      Dot-Tux Server is now offline.      #${C_RESET}"
echo -e "${C_GREEN}#                                          #${C_RESET}"
echo -e "${C_GREEN}############################################${C_RESET}"
echo ""
