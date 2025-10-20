#!/usr/bin/env bash

# ==============================================================================
# Dot-Tux Start Script (Fully Upgraded & su/tsu Aware)
#
# This script intelligently detects the correct superuser command (tsu or su)
# and provides accurate instructions for users on rooted devices.
# ==============================================================================

# --- Color Definitions ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

# --- Helper Functions ---
print_info() {
    echo -e "${C_BLUE}[INFO] $1${C_RESET}"
}

print_success() {
    echo -e "${C_GREEN}[SUCCESS] $1${C_RESET}"
}

print_error() {
    echo -e "${C_RED}[ERROR] $1${C_RESET}"
}

print_warning() {
    echo -e "${C_YELLOW}[WARNING] $1${C_RESET}"
}

# --- Configuration ---
NGINX_CONF_PATH="/data/data/com.termux/files/usr/etc/nginx/nginx.conf"
LOG_FILE="app.log"

# --- Main Start Logic ---
clear
echo -e "${C_GREEN}Starting Dot-Tux Server...${C_RESET}"
echo ""

# --- Step 1: Acquire Termux Wakelock ---
print_info "Acquiring Termux wakelock to prevent sleeping..."
termux-wake-lock
print_success "Wakelock acquired."
echo ""
sleep 1

# --- Step 2: Start Nginx Server ---
print_info "Starting Nginx web server..."

# NEW: Intelligently check for super-user privileges and the correct command.
if [ "$(whoami)" != "root" ]; then
    SU_CMD=""
    # Check for 'tsu' first, as it's common in Termux root packages.
    if command -v tsu >/dev/null 2>&1; then
        SU_CMD="tsu -c ./start.sh"
    # Fallback to standard 'su' if 'tsu' is not found.
    elif command -v su >/dev/null 2>&1; then
        SU_CMD="su -c ./start.sh"
    fi

    # If a valid superuser command was found, show the warning.
    if [ -n "$SU_CMD" ]; then
        print_warning "You are not running as a super-user (root)."
        print_warning "If Nginx fails, it may be because it cannot bind to port 80."
        print_warning "On rooted devices, try running this script with: '${SU_CMD}'"
        echo ""
        sleep 3
    fi
fi

if pgrep -x "nginx" > /dev/null; then
    print_success "Nginx is already running."
else
    # Start Nginx with the CORRECT config path for Termux
    nginx -c "$NGINX_CONF_PATH"
    sleep 1 # Give it a moment to start
    if pgrep -x "nginx" > /dev/null; then
        print_success "Nginx started successfully."
    else
        print_error "Nginx failed to start. Run 'nginx -t -c ${NGINX_CONF_PATH}' to test your config."
        termux-wake-unlock
        exit 1
    fi
fi
echo ""
sleep 1

# --- Step 3: Start the Python Control Panel ---
print_info "Starting the Dot-Tux control panel (app.py)..."
if [ ! -f "app.py" ]; then
    print_error "'app.py' not found. Cannot start the control panel."
    termux-wake-unlock
    exit 1
fi

if pgrep -f "python app.py" > /dev/null; then
    print_success "Control panel is already running."
else
    # Use 'nohup' and redirect stdout/stderr to a log file for debugging
    nohup python app.py > "$LOG_FILE" 2>&1 &
    sleep 2 # Give it a moment to start up

    if pgrep -f "python app.py" > /dev/null; then
        print_success "Control panel is running in the background."
    else
        print_error "Control panel (app.py) failed to start. Check '${LOG_FILE}' for errors."
        termux-wake-unlock
        exit 1
    fi
fi
echo ""

# --- Final Instructions ---
IP_ADDR=$(ifconfig wlan0 | grep 'inet ' | awk '{print $2}')
echo -e "${C_GREEN}############################################${C_RESET}"
echo -e "${C_GREEN}#                                          #${C_RESET}"
echo -e "${C_GREEN}#      Dot-Tux Server is now LIVE! 🚀      #${C_RESET}"
echo -e "${C_GREEN}#                                          #${C_RESET}"
echo -e "${C_GREEN}############################################${C_RESET}"
echo ""
print_info "Your control panel should be accessible at:"
echo -e "${C_YELLOW}http://dot.tux${C_RESET} or ${C_YELLOW}http://${IP_ADDR}${C_RESET}"
echo ""
print_info "To stop the server, run: ${C_GREEN}./stop.sh${C_RESET}"
echo ""

