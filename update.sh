#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# Dot-Tux Update Script
#
# This script stops the server, pulls the latest version from the Git
# repository, and restarts the server.
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

# --- Main Update Logic ---
clear
echo -e "${C_GREEN}Starting Dot-Tux Update Process...${C_RESET}"
echo ""

# --- Step 1: Check for Git Repository ---
if [ ! -d ".git" ]; then
    print_error "This does not appear to be a Git repository. Update failed."
    exit 1
fi
print_info "Git repository found."
echo ""
sleep 1

# --- Step 2: Stop the Server ---
print_info "Stopping the Dot-Tux server to prepare for the update..."
if [ ! -f "stop.sh" ]; then
    print_error "'stop.sh' not found. Cannot stop the server automatically."
    print_warning "Please stop Nginx and the python app.py process manually before updating."
    exit 1
fi

# Execute the stop script
./stop.sh
echo "" # stop.sh already prints messages, just add a newline.
print_success "Server has been stopped."
echo ""
sleep 2

# --- Step 3: Pull Latest Changes from Git ---
print_info "Fetching the latest updates from the Git repository..."

# Stash any local changes to prevent conflicts
git stash
if [ $? -ne 0 ]; then
    print_error "Failed to stash local changes. Please commit or discard them and try again."
    exit 1
fi

# Pull the latest code from the 'main' branch (or 'master' if that's your default)
git pull origin main
if [ $? -ne 0 ]; then
    print_error "Failed to pull updates from Git. Please check your internet connection."
    print_warning "Attempting to restore your previous state..."
    git stash pop
    exit 1
fi

# Apply the stashed changes back
git stash pop > /dev/null 2>&1

print_success "Successfully updated to the latest version."
echo ""
sleep 1

# --- Step 4: Restart the Server ---
print_info "Restarting the Dot-Tux server..."
if [ ! -f "start.sh" ]; then
    print_error "'start.sh' not found. Cannot restart the server automatically."
    print_warning "Update is complete, but you will need to start the server manually."
    exit 1
fi

# Execute the start script
./start.sh

# The start script provides its own final success message, so we don't need another one.
