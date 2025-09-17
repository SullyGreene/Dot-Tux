#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# Dot-Tux Start Script
#
# This script starts the Nginx server and the Python control panel,
# acquiring a wakelock to ensure the processes stay alive.
# ==============================================================================

# --- Color Definitions for pretty printing ---
C_RESET='\033[0m'
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

# --- Main Start Logic ---
clear
echo -e "${C_GREEN}Starting Dot-Tux Server...${C_RESET}"
echo ""

# --- Step 1: Acquire Termux Wakelock ---
print_info "Acquiring Termux wakelock to prevent the server from sleeping..."
termux-wake-lock
print_success "Wakelock acquired."
echo ""
sleep 1

# --- Step 2: Start Nginx Server ---
print_info "Starting Nginx web server..."
# The 'nginx' command starts the server as a daemon process.
nginx
# A simple check to see if the process is running.
if pgrep -x "nginx" > /dev/null
then
    print_success "Nginx is running."
else
    print_error "Nginx failed to start. Run 'nginx -t' to test your configuration."
    exit 1
fi
echo ""
sleep 1

# --- Step 3: Start the Python Control Panel ---
print_info "Starting the Dot-Tux control panel (app.py)..."
# Check if the app.py file exists before trying to run it
if [ ! -f "app.py" ]; then
    print_error "'app.py' not found. Cannot start the control panel."
    exit 1
fi

# Run the python script in the background using '&'
# Use 'nohup' to ensure it keeps running even if the shell is closed.
nohup python app.py &

# Give it a moment to start up
sleep 2

# Check if the python process is running
if pgrep -f "python app.py" > /dev/null
then
    print_success "Control panel is running."
else
    print_error "Control panel (app.py) failed to start. Check for errors."
    exit 1
fi
echo ""

# --- Final Instructions ---
IP_ADDR=$(ifconfig wlan0 | grep 'inet ' | awk '{print $2}')
echo -e "${C_GREEN}############################################${C_RESET}"
echo -e "${C_GREEN}#                                          #${C_RESET}"
echo -e "${C_GREEN}#   Dot-Tux Server is now LIVE! 🚀         #${C_RESET}"
echo -e "${C_GREEN}#                                          #${C_RESET}"
echo -e "${C_GREEN}############################################${C_RESET}"
echo ""
print_info "Your control panel should be accessible at:"
echo -e "${C_YELLOW}http://dot.tux:8080${C_RESET} or ${C_YELLOW}http://${IP_ADDR}:8080${C_RESET}"
echo ""
print_info "To stop the server, run: ${C_GREEN}./stop.sh${C_RESET}"
echo ""
