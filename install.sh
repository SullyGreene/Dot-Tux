#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# Dex-Tux Installation Script
#
# This script prepares the Termux environment for Dex-Tux by installing
# dependencies, setting up directories, and configuring auto-start on boot.
# ==============================================================================

# --- Color Definitions for pretty printing ---
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

print_warning() {
    echo -e "${C_YELLOW}[WARNING] $1${C_RESET}"
}

print_error() {
    echo -e "${C_RED}[ERROR] $1${C_RESET}"
}


# --- Main Installation ---

clear
echo -e "${C_GREEN}"
echo "###################################"
echo "#                                 #"
echo "#      Welcome to Dex-Tux         #"
echo "#    Termux Domain Manager        #"
echo "#                                 #"
echo "###################################"
echo -e "${C_RESET}"
echo "This script will install and configure Dex-Tux on your device."
echo ""
sleep 3

# --- Step 1: Update Termux Packages ---
print_info "Updating Termux package lists..."
pkg update -y
print_info "Upgrading installed packages..."
pkg upgrade -y
print_success "Termux packages are up to date."
echo ""
sleep 1

# --- Step 2: Install Dependencies ---
print_info "Installing required packages (nginx, python, git)..."
pkg install -y nginx python git
if [ $? -ne 0 ]; then
    print_error "Failed to install dependencies. Please check your internet connection."
    exit 1
fi
print_success "All dependencies are installed."
echo ""
sleep 1

# --- Step 3: Create Directory Structure ---
print_info "Creating necessary directories..."
mkdir -p ~/sites
mkdir -p ~/.termux/boot
# The 'dex.tux' directory will be managed by app.py, but we ensure its parent exists.
print_success "Directory structure is ready."
echo ""
sleep 1

# --- Step 4: Configure Nginx ---
NGINX_CONF_PATH="$PREFIX/etc/nginx/nginx.conf"
print_info "Setting up Nginx configuration..."

# Check if an nginx.conf file exists in the repo directory
if [ ! -f "nginx.conf" ]; then
    print_error "'nginx.conf' not found in the repository root. Cannot proceed."
    exit 1
fi

# Backup existing Nginx config if it's not the default one
if [ -f "$NGINX_CONF_PATH" ]; then
    print_warning "Existing Nginx config found. Backing it up to ${NGINX_CONF_PATH}.bak"
    mv "$NGINX_CONF_PATH" "${NGINX_CONF_PATH}.bak"
fi

# Copy the repository's config file
cp nginx.conf "$NGINX_CONF_PATH"
print_success "Nginx has been configured."
echo ""
sleep 1

# --- Step 5: Set up Termux:Boot script ---
BOOT_SCRIPT_PATH=~/.termux/boot/start-dextux
PROJECT_DIR=$(pwd) # Get the absolute path of the Dex-Tux repo

print_info "Setting up auto-start script for Termux:Boot..."

# Create the boot script using a heredoc
cat <<EOF > "$BOOT_SCRIPT_PATH"
#!/data/data/com.termux/files/usr/bin/sh

# This script is executed by Termux:Boot on device startup.

# Wait for network to be ready
sleep 20

# Navigate to the Dex-Tux project directory
cd "$PROJECT_DIR"

# Execute the main start script
./start.sh
EOF

# Make the script executable
chmod +x "$BOOT_SCRIPT_PATH"
print_success "Auto-start script created at ${BOOT_SCRIPT_PATH}"
echo ""
sleep 1


# --- Final Instructions ---
echo -e "${C_GREEN}"
echo "###################################"
echo "#                                 #"
echo "#    Installation Complete!       #"
echo "#                                 #"
echo "###################################"
echo -e "${C_RESET}"
echo ""
print_warning "IMPORTANT - Final manual steps:"
echo -e "1. Make sure you have installed the ${C_YELLOW}Termux:Boot app${C_RESET} from F-Droid."
echo -e "2. ${C_RED}Disable Battery Optimization${C_RESET} for both 'Termux' and 'Termux:Boot' apps in your phone's settings. This is crucial!"
echo -e "3. Find your device's local IP with the ${C_YELLOW}'ifconfig'${C_RESET} command."
echo -e "4. Edit the 'hosts' file on your computer to point 'dex.tux' to that IP."
echo ""
print_info "You can now start the server for the first time by running:"
echo -e "${C_GREEN}./start.sh${C_RESET}"
echo ""
