#!/usr/bin/env bash
# ==============================================================================
# Dot-Tux Start Script (Fully Upgraded & Modular)
# ==============================================================================
C_RESET='\033[0m';C_RED='\033[0;31m';C_GREEN='\033[0;32m';C_BLUE='\033[0;34m';C_YELLOW='\033[1;33m'
print_info() { echo -e "${C_BLUE}[INFO] $1${C_RESET}"; }
print_success() { echo -e "${C_GREEN}[SUCCESS] $1${C_RESET}"; }
print_error() { echo -e "${C_RED}[ERROR] $1${C_RESET}"; }
print_warning() { echo -e "${C_YELLOW}[WARNING] $1${C_RESET}"; }

CHOICE_FILE="$HOME/.dottux_choice"
LOG_FILE="app.log"

if [ ! -f "$CHOICE_FILE" ]; then
    print_error "Server choice file not found. Run the installer first."
    exit 1
fi
SERVER_CHOICE=$(cat "$CHOICE_FILE")

clear
echo -e "${C_GREEN}Starting Dot-Tux Server...${C_RESET}\n"
print_info "Acquiring Termux wakelock..."
termux-wake-lock
print_success "Wakelock acquired.\n" && sleep 1

print_info "Starting $SERVER_CHOICE web server..."
if [ "$(whoami)" != "root" ]; then
    SU_CMD=""
    if command -v tsu >/dev/null 2>&1; then SU_CMD="tsu -c ./start.sh";
    elif command -v su >/dev/null 2>&1; then SU_CMD="su -c ./start.sh"; fi
    if [ -n "$SU_CMD" ]; then
        print_warning "You are not running as root."
        print_warning "If server fails, it may not be able to bind to port 80."
        print_warning "On rooted devices, try: '${SU_CMD}'\n" && sleep 3
    fi
fi

start_server() {
    local process_name=$1
    local start_command=$2
    local test_command=$3
    if pgrep -x "$process_name" > /dev/null; then
        print_success "${process_name^} is already running."
    else
        eval "$start_command"
        sleep 1
        if pgrep -x "$process_name" > /dev/null; then
            print_success "${process_name^} started successfully."
        else
            print_error "${process_name^} failed to start. Run '${test_command}' to test."
            termux-wake-unlock && exit 1
        fi
    fi
}

case $SERVER_CHOICE in
    "nginx")    start_server "nginx" "nginx -c $PREFIX/etc/nginx/nginx.conf" "nginx -t -c $PREFIX/etc/nginx/nginx.conf" ;;
    "caddy")    start_server "caddy" "caddy start --config $PREFIX/etc/caddy/Caddyfile" "caddy validate --config $PREFIX/etc/caddy/Caddyfile" ;;
    "lighttpd") start_server "lighttpd" "lighttpd -f $PREFIX/etc/lighttpd/lighttpd.conf" "lighttpd -tt -f $PREFIX/etc/lighttpd/lighttpd.conf" ;;
esac
echo "" && sleep 1

print_info "Starting the Dot-Tux control panel (app.py)..."
if [ ! -f "app.py" ]; then
    print_error "'app.py' not found. Cannot start the control panel."
    termux-wake-unlock && exit 1
fi

if pgrep -f "python app.py" > /dev/null; then
    print_success "Control panel is already running."
else
    nohup python app.py > "$LOG_FILE" 2>&1 &
    sleep 2
    if pgrep -f "python app.py" > /dev/null; then
        print_success "Control panel is running in the background."
    else
        print_error "Control panel failed to start. Check '${LOG_FILE}' for errors."
        termux-wake-unlock && exit 1
    fi
fi
echo ""

IP_ADDR=$(ifconfig wlan0 | grep 'inet ' | awk '{print $2}' || echo "not connected")
echo -e "${C_GREEN}############################################${C_RESET}"
echo -e "${C_GREEN}#                                          #${C_RESET}"
echo -e "${C_GREEN}#     Dot-Tux Server is now LIVE! 🚀       #${C_RESET}"
echo -e "${C_GREEN}#                                          #${C_RESET}"
echo -e "${C_GREEN}############################################${C_RESET}\n"
print_info "Your control panel should be accessible at:"
if [ "$IP_ADDR" != "not connected" ]; then
    echo -e "${C_YELLOW}http://dot.tux${C_RESET} or ${C_YELLOW}http://${IP_ADDR}${C_RESET}"
else
    echo -e "${C_YELLOW}http://dot.tux${C_RESET} or ${C_YELLOW}http://localhost:8080${C_RESET} (WiFi not detected)"
fi
echo ""
print_info "To stop the server, run: ${C_GREEN}./stop.sh${C_RESET}\n"
