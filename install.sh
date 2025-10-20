#!/usr/bin/env bash

# ==============================================================================
# Dot-Tux Modular Installation Script (Fully Upgraded)
#
# This script allows the user to choose their preferred web server, installs
# all dependencies, and correctly configures Termux:Boot.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Color Definitions ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

# --- Helper Functions ---
print_info() { echo -e "${C_BLUE}[INFO] $1${C_RESET}"; }
print_success() { echo -e "${C_GREEN}[SUCCESS] $1${C_RESET}"; }
print_warning() { echo -e "${C_YELLOW}[WARNING] $1${C_RESET}"; }
print_error() { echo -e "${C_RED}[ERROR] $1${C_RESET}"; }

# --- Configuration Store ---
# This file will store the user's choice so other scripts can read it.
CHOICE_FILE="$HOME/.dottux_choice"

# --- Pre-flight Checks ---
if [ "$(whoami)" == "root" ]; then
    print_error "This script should be run as the normal Termux user, not root."
    exit 1
fi

# --- Main Installation ---
clear
echo -e "${C_GREEN}"
echo "###################################"
echo "#                                 #"
echo "#       Welcome to Dot-Tux        #"
echo "#     Termux Domain Manager       #"
echo "#                                 #"
echo "###################################"
echo -e "${C_RESET}"

# --- Step 1: Web Server Selection ---
print_info "Please choose a web server to install:"
PS3="Enter the number for your choice: "
options=("Nginx (Recommended Standard)" "Caddy (Simple & Powerful)" "Lighttpd (Extremely Lightweight)" "Quit")
select opt in "${options[@]}"; do
    case $opt in
        "Nginx (Recommended Standard)")
            SERVER_CHOICE="nginx"
            break
            ;;
        "Caddy (Simple & Powerful)")
            SERVER_CHOICE="caddy"
            break
            ;;
        "Lighttpd (Extremely Lightweight)")
            SERVER_CHOICE="lighttpd"
            break
            ;;
        "Quit")
            exit
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done

# Save the choice for other scripts
echo "$SERVER_CHOICE" > "$CHOICE_FILE"
print_success "You have selected: $SERVER_CHOICE. This will be saved for all other scripts."
echo ""
sleep 2

# --- Step 2: Package Installation ---
print_info "Updating Termux packages..."
pkg update -y && pkg upgrade -y
print_info "Installing dependencies (git, python, and $SERVER_CHOICE)..."
pkg install -y git python "$SERVER_CHOICE"
print_info "Installing Python dependencies (flask)..."
pip install flask
print_success "All dependencies are installed."
echo ""
sleep 1

# --- Step 3: Directory Structure ---
print_info "Creating necessary directories..."
mkdir -p "$HOME/sites"
mkdir -p "$HOME/.termux/boot"
# Create a common directory for site configs for all server types
mkdir -p "$PREFIX/etc/dottux/sites-enabled"
print_success "Directory structure is ready."
echo ""
sleep 1

# --- Step 4: Configure Web Server ---
print_info "Configuring $SERVER_CHOICE..."

case $SERVER_CHOICE in
    "nginx")
        NGINX_CONF_PATH="$PREFIX/etc/nginx/nginx.conf"
        mv "$NGINX_CONF_PATH" "${NGINX_CONF_PATH}.bak" 2>/dev/null || true
        cat <<EOF > "$NGINX_CONF_PATH"
worker_processes 1;
events { worker_connections 1024; }
http {
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;
    # Include all site configurations from our custom directory
    include $PREFIX/etc/dottux/sites-enabled/*;
}
EOF
        ;;
    "caddy")
        CADDYFILE_PATH="$PREFIX/etc/caddy/Caddyfile"
        mv "$CADDYFILE_PATH" "${CADDYFILE_PATH}.bak" 2>/dev/null || true
        cat <<EOF > "$CADDYFILE_PATH"
# Main Caddyfile for Dot-Tux
# This file imports all configurations from the sites-enabled directory.
import $PREFIX/etc/dottux/sites-enabled/*
EOF
        ;;
    "lighttpd")
        LIGHTTPD_CONF_PATH="$PREFIX/etc/lighttpd/lighttpd.conf"
        mv "$LIGHTTPD_CONF_PATH" "${LIGHTTPD_CONF_PATH}.bak" 2>/dev/null || true
        cat <<EOF > "$LIGHTTPD_CONF_PATH"
# Main lighttpd.conf for Dot-Tux
server.document-root = "$HOME/sites"
server.port = 80
server.modules = ( "mod_access", "mod_proxy", "mod_accesslog" )
mimetype.assign = ( ".html" => "text/html", ".js" => "text/javascript", ".css" => "text/css" )

# Include all site configurations from our custom directory.
# lighttpd doesn't support wildcard includes, so we use include_shell.
include_shell "cat $PREFIX/etc/dottux/sites-enabled/*"
EOF
        ;;
esac
print_success "$SERVER_CHOICE has been configured."
echo ""
sleep 1

# --- Step 5: Set up Termux:Boot script ---
BOOT_SCRIPT_PATH="$HOME/.termux/boot/start-dottux"
# Get the absolute path of the current script's directory
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

print_info "Setting up auto-start script for Termux:Boot..."

cat <<EOF > "$BOOT_SCRIPT_PATH"
#!/usr/bin/env sh

# This script is executed by Termux:Boot on device startup.

# Wait for network to be ready (30 seconds should be safe)
sleep 30

# Navigate to the Dot-Tux project directory
cd "${PROJECT_DIR}"

# Execute the main start script
./start.sh
EOF

# Make the script executable
chmod +x "$BOOT_SCRIPT_PATH"
print_success "Auto-start script created at ${BOOT_SCRIPT_PATH}"
echo ""
sleep 1

# --- Step 6: Final Instructions ---
echo -e "${C_GREEN}"
echo "###################################"
echo "#                                 #"
echo "#     Installation Complete!      #"
echo "#                                 #"
echo "###################################"
echo -e "${C_RESET}"
echo ""
print_warning "IMPORTANT - FINAL MANUAL STEPS:"
echo -e "1. Install the ${C_YELLOW}Termux:Boot app${C_RESET} from F-Droid or the Play Store."
echo -e "2. ${C_RED}Disable Battery Optimization${C_RESET} for both 'Termux' and 'Termux:Boot' in your phone's settings."
echo -e "3. Find your phone's IP address with the ${C_YELLOW}ifconfig${C_RESET} command."
echo -e "4. Edit the 'hosts' file on your computer to point 'dot.tux' to that IP."
echo ""
print_info "You can now start the server for the first time by running:"
echo -e "${C_GREEN}./start.sh${C_RESET}"
echo ""
