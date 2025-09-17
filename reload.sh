#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# Dot-Tux Reload Script
#
# This script is called by the Python application to safely test and apply
# new Nginx configurations after adding or removing a domain.
# ==============================================================================

# --- Color Definitions for pretty printing ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_RED='\033[0;31m'

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

# --- Main Reload Logic ---
echo ""
print_info "Attempting to reload Nginx configuration..."
echo ""

# --- Step 1: Test the Nginx configuration for syntax errors ---
# This is a critical safety check. 'nginx -t' will test the config files.
# We redirect stderr to stdout (2>&1) to capture all output.
NGINX_TEST_OUTPUT=$(nginx -t 2>&1)

# Check the exit code of the test command. 0 means success.
if [ $? -eq 0 ]; then
    print_success "Nginx configuration syntax is OK."
    echo ""

    # --- Step 2: Reload Nginx if the test passed ---
    print_info "Reloading Nginx..."
    nginx -s reload
    print_success "Nginx has been reloaded successfully."
    echo ""
else
    # --- Step 3: Report an error if the test failed ---
    print_error "Nginx configuration test failed! Server was NOT reloaded."
    echo -e "${C_RED}The running configuration has not been changed.${C_RESET}"
    echo ""
    print_error "Details:"
    echo -e "$NGINX_TEST_OUTPUT" # Print the detailed error message from Nginx
    echo ""
    exit 1 # Exit with a non-zero status to indicate failure
fi

exit 0
