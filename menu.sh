#!/usr/bin/env bash

# ==============================================================================
# Xray Fragment Fingerprint - Linux Management TUI
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XRAY_BIN="${SCRIPT_DIR}/xray"
CONFIG_FILE="${SCRIPT_DIR}/config.json"
SERVICE_NAME="xray-fragment"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
SYSTEMD_USER_SERVICE="${SYSTEMD_USER_DIR}/${SERVICE_NAME}.service"
SYSTEMD_SYSTEM_SERVICE="/etc/systemd/system/${SERVICE_NAME}.service"

# Color Codes
C_RESET="\033[0m"
C_CYAN="\033[1;36m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_GRAY="\033[0;37m"
C_DGRAY="\033[1;30m"
C_MAGENTA="\033[1;35m"

# Detect System Architecture
detect_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64)
            echo "64"
            ;;
        aarch64|arm64)
            echo "arm64-v8a"
            ;;
        armv7l|armv7|armhf)
            echo "arm32-v7a"
            ;;
        i386|i686)
            echo "32"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Determine if root or user systemd should be used
has_sudo() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        return 0
    fi
    return 1
}

# Get running status
get_status() {
    local pids
    pids="$(pgrep -f "${XRAY_BIN}" 2>/dev/null || true)"
    if [ -n "$pids" ]; then
        local count
        count="$(echo "$pids" | wc -l | tr -d ' ')"
        echo -e "${C_GREEN}RUNNING (${count} process, PID: $(echo $pids | tr '\n' ' '))${C_RESET}"
    else
        echo -e "${C_DGRAY}STOPPED${C_RESET}"
    fi
}

# Get systemd service status
get_service_status() {
    if command -v systemctl >/dev/null 2>&1; then
        if [ -f "$SYSTEMD_SYSTEM_SERVICE" ]; then
            if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
                echo -e "${C_GREEN}ACTIVE (System Service)${C_RESET}"
            elif systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
                echo -e "${C_YELLOW}ENABLED / INACTIVE (System Service)${C_RESET}"
            else
                echo -e "${C_DGRAY}INSTALLED / INACTIVE (System Service)${C_RESET}"
            fi
            return
        fi

        if [ -f "$SYSTEMD_USER_SERVICE" ]; then
            if systemctl --user is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
                echo -e "${C_GREEN}ACTIVE (User Service)${C_RESET}"
            elif systemctl --user is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
                echo -e "${C_YELLOW}ENABLED / INACTIVE (User Service)${C_RESET}"
            else
                echo -e "${C_DGRAY}INSTALLED / INACTIVE (User Service)${C_RESET}"
            fi
            return
        fi
    fi
    echo -e "${C_DGRAY}NOT INSTALLED${C_RESET}"
}

# Get Xray Version
get_version() {
    if [ -x "$XRAY_BIN" ]; then
        local ver
        ver="$("$XRAY_BIN" version 2>/dev/null | head -n1 | awk '{print $2}' || true)"
        if [ -n "$ver" ]; then
            echo "$ver"
            return
        fi
    fi
    echo "Not installed"
}

# Display Header
show_header() {
    clear
    echo -e "${C_CYAN}================================================================${C_RESET}"
    echo -e "${C_YELLOW}                XRAY FRAGMENT FINGERPRINT MANAGER (Linux)       ${C_RESET}"
    echo -e "${C_CYAN}================================================================${C_RESET}"
    echo -e "${C_GRAY} Working Dir   : ${SCRIPT_DIR}${C_RESET}"
    echo -e "${C_GRAY} Architecture  : $(uname -m)${C_RESET}"
    echo -e "${C_GRAY} Xray Version  : $(get_version)${C_RESET}"
    echo -e "${C_GRAY} Status        : $(get_status)"
    echo -e "${C_GRAY} Systemd Serv. : $(get_service_status)"
    echo -e "${C_CYAN}================================================================${C_RESET}"
    echo ""
}

pause() {
    echo ""
    echo -e "${C_DGRAY}Press Enter to return to menu...${C_RESET}"
    read -r _
}

# 1. Start in Foreground
start_foreground() {
    show_header
    echo -e "${C_YELLOW}[1] STARTING XRAY IN FOREGROUND (Terminal)...${C_RESET}"
    echo -e "${C_DGRAY}Press Ctrl+C to stop Xray and return to menu.${C_RESET}"
    echo -e "${C_GRAY}----------------------------------------------------------------${C_RESET}"

    if [ ! -x "$XRAY_BIN" ]; then
        echo -e "${C_RED}Error: xray binary not found or not executable at ${XRAY_BIN}${C_RESET}"
        echo -e "${C_YELLOW}Please select Option [4] from the menu to download Xray-core first.${C_RESET}"
        pause
        return
    fi

    if [ -f "$CONFIG_FILE" ]; then
        "$XRAY_BIN" run -c "$CONFIG_FILE" || true
    else
        "$XRAY_BIN" run || true
    fi

    echo ""
    echo -e "${C_YELLOW}Xray stopped.${C_RESET}"
    pause
}

# 2. Setup Systemd Service (with User Service Fallback)
setup_systemd_service() {
    show_header
    echo -e "${C_YELLOW}[2] INSTALLING & CONFIGURING SYSTEMD SERVICE...${C_RESET}"
    echo ""

    if [ ! -x "$XRAY_BIN" ]; then
        echo -e "${C_RED}Error: xray binary not found. Download it first (Option 4).${C_RESET}"
        pause
        return
    fi

    local service_content="[Unit]
Description=Xray Fragment Fingerprint Service
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${SCRIPT_DIR}
ExecStart=${XRAY_BIN} run -c ${CONFIG_FILE}
Restart=on-failure
RestartSec=5s
LimitNOFILE=65535

[Install]
WantedBy=default.target"

    local use_system=false
    if has_sudo || [ "$EUID" -eq 0 ]; then
        read -r -p "Install as System-wide service (requires root/sudo)? [Y/n]: " ans
        if [[ "$ans" =~ ^[Yy]$ || -z "$ans" ]]; then
            use_system=true
        fi
    fi

    if [ "$use_system" = true ]; then
        echo "Installing system-wide service at $SYSTEMD_SYSTEM_SERVICE..."
        if [ "$EUID" -eq 0 ]; then
            echo "$service_content" > "$SYSTEMD_SYSTEM_SERVICE"
            systemctl daemon-reload
            systemctl enable "$SERVICE_NAME"
            systemctl restart "$SERVICE_NAME"
        else
            echo "$service_content" | sudo tee "$SYSTEMD_SYSTEM_SERVICE" > /dev/null
            sudo systemctl daemon-reload
            sudo systemctl enable "$SERVICE_NAME"
            sudo systemctl restart "$SERVICE_NAME"
        fi
        echo -e "${C_GREEN}[✓] System service installed, enabled on boot, and started!${C_RESET}"
    else
        echo "Installing User-level service at $SYSTEMD_USER_SERVICE..."
        mkdir -p "$SYSTEMD_USER_DIR"
        echo "$service_content" > "$SYSTEMD_USER_SERVICE"
        systemctl --user daemon-reload
        systemctl --user enable "$SERVICE_NAME"
        systemctl --user restart "$SERVICE_NAME"
        
        # Enable lingering so user service runs without active login session if loginctl is present
        if command -v loginctl >/dev/null 2>&1; then
            loginctl enable-linger "$USER" 2>/dev/null || true
        fi
        echo -e "${C_GREEN}[✓] User service installed, enabled for auto-start, and started!${C_RESET}"
    fi

    pause
}

# 3. Remove Systemd Service
remove_systemd_service() {
    show_header
    echo -e "${C_YELLOW}[3] REMOVING SYSTEMD SERVICE...${C_RESET}"
    echo ""

    local removed=false

    if [ -f "$SYSTEMD_SYSTEM_SERVICE" ]; then
        echo "Removing system service..."
        if [ "$EUID" -eq 0 ]; then
            systemctl stop "$SERVICE_NAME" 2>/dev/null || true
            systemctl disable "$SERVICE_NAME" 2>/dev/null || true
            rm -f "$SYSTEMD_SYSTEM_SERVICE"
            systemctl daemon-reload
        else
            sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
            sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || true
            sudo rm -f "$SYSTEMD_SYSTEM_SERVICE"
            sudo systemctl daemon-reload
        fi
        removed=true
        echo -e "${C_GREEN}[✓] System service removed successfully.${C_RESET}"
    fi

    if [ -f "$SYSTEMD_USER_SERVICE" ]; then
        echo "Removing user service..."
        systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
        systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
        rm -f "$SYSTEMD_USER_SERVICE"
        systemctl --user daemon-reload
        removed=true
        echo -e "${C_GREEN}[✓] User service removed successfully.${C_RESET}"
    fi

    if [ "$removed" = false ]; then
        echo -e "${C_YELLOW}No systemd service was found installed.${C_RESET}"
    fi

    pause
}

# 4. Download / Update Xray-core
download_xray() {
    show_header
    echo -e "${C_YELLOW}[4] DOWNLOADING / UPDATING LATEST XRAY-CORE...${C_RESET}"
    echo ""

    local arch_suffix
    arch_suffix="$(detect_arch)"
    if [ "$arch_suffix" = "unknown" ]; then
        echo -e "${C_RED}[X] Unsupported architecture: $(uname -m)${C_RESET}"
        pause
        return
    fi

    local target_zip_name="Xray-linux-${arch_suffix}.zip"
    echo -e "${C_GRAY}Target Package : ${target_zip_name}${C_RESET}"

    # Check dependencies
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        echo -e "${C_RED}[X] Error: curl or wget is required.${C_RESET}"
        pause
        return
    fi

    if ! command -v unzip >/dev/null 2>&1; then
        echo -e "${C_RED}[X] Error: unzip is required. Please install it (e.g., sudo apt install unzip / sudo dnf install unzip).${C_RESET}"
        pause
        return
    fi

    local api_url="https://api.github.com/repos/XTLS/Xray-core/releases/latest"
    echo -e "${C_GRAY}Fetching release metadata from GitHub...${C_RESET}"

    local download_url=""
    local tag_name=""

    # 1. Try parsing using python3 if available (safest & most accurate)
    if command -v python3 >/dev/null 2>&1; then
        download_url="$(python3 -c "
import urllib.request, json
try:
    req = urllib.request.Request('${api_url}', headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read().decode())
        for a in data.get('assets', []):
            if a.get('name') == '${target_zip_name}':
                print(a.get('browser_download_url', ''))
                break
except:
    pass
" 2>/dev/null || true)"
    fi

    # 2. Fallback to regex extraction via curl / wget
    if [ -z "$download_url" ]; then
        local raw_content=""
        if command -v curl >/dev/null 2>&1; then
            raw_content="$(curl -sSL -H "User-Agent: Mozilla/5.0" "$api_url" 2>/dev/null || true)"
        else
            raw_content="$(wget -qO- --header="User-Agent: Mozilla/5.0" "$api_url" 2>/dev/null || true)"
        fi
        download_url="$(echo "$raw_content" | grep -o "https://[^\"]*download/[^\"]*/${target_zip_name}" | head -n1 || true)"
    fi

    # 3. Direct GitHub release fallback URL
    if [ -z "$download_url" ]; then
        echo -e "${C_YELLOW}GitHub API limit or metadata issue. Using direct release download link...${C_RESET}"
        download_url="https://github.com/XTLS/Xray-core/releases/latest/download/${target_zip_name}"
    else
        echo -e "${C_GREEN}[✓] Download link resolved successfully.${C_RESET}"
    fi

    local temp_zip="${SCRIPT_DIR}/xray_temp.zip"
    local temp_dir="${SCRIPT_DIR}/xray_temp_extract"

    echo -e "${C_CYAN}Downloading ${target_zip_name}...${C_RESET}"
    rm -f "$temp_zip"
    rm -rf "$temp_dir"

    if command -v curl >/dev/null 2>&1; then
        curl -L --fail --progress-bar -o "$temp_zip" "$download_url" || {
            echo -e "${C_RED}[X] Download failed. Check your internet connection or proxy.${C_RESET}"
            rm -f "$temp_zip"
            pause
            return
        }
    else
        wget -q --show-progress -O "$temp_zip" "$download_url" || {
            echo -e "${C_RED}[X] Download failed. Check your internet connection or proxy.${C_RESET}"
            rm -f "$temp_zip"
            pause
            return
        }
    fi

    # Verify if zip file is valid
    if ! unzip -tq "$temp_zip" >/dev/null 2>&1; then
        echo -e "${C_RED}[X] Error: Downloaded file is not a valid zip archive.${C_RESET}"
        rm -f "$temp_zip"
        pause
        return
    fi

    echo -e "${C_GRAY}Extracting package...${C_RESET}"
    mkdir -p "$temp_dir"
    unzip -q -o "$temp_zip" -d "$temp_dir"

    # Stop running process if any
    pkill -f "${XRAY_BIN}" 2>/dev/null || true

    # Backup old binary
    if [ -f "$XRAY_BIN" ]; then
        cp "$XRAY_BIN" "${XRAY_BIN}.bak"
    fi

    # Move binaries and assets
    if [ -f "${temp_dir}/xray" ]; then
        mv "${temp_dir}/xray" "$XRAY_BIN"
        chmod +x "$XRAY_BIN"
        echo -e "${C_GREEN}[✓] Installed xray binary${C_RESET}"
    else
        echo -e "${C_RED}[X] Error: xray binary not found in extracted archive.${C_RESET}"
    fi

    for asset in geoip.dat geosite.dat; do
        if [ -f "${temp_dir}/${asset}" ]; then
            mv "${temp_dir}/${asset}" "${SCRIPT_DIR}/${asset}"
            echo -e "${C_GREEN}[✓] Installed ${asset}${C_RESET}"
        fi
    done

    # Clean up
    rm -rf "$temp_zip" "$temp_dir"

    echo ""
    echo -e "${C_GREEN}[✓] Xray successfully updated! Current version: $(get_version)${C_RESET}"
    pause
}

# 5. Stop All Processes
stop_all() {
    show_header
    echo -e "${C_YELLOW}[5] STOPPING XRAY PROCESSES & SERVICES...${C_RESET}"
    echo ""

    if [ -f "$SYSTEMD_SYSTEM_SERVICE" ]; then
        if [ "$EUID" -eq 0 ]; then
            systemctl stop "$SERVICE_NAME" 2>/dev/null || true
        else
            sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
        fi
    fi

    if [ -f "$SYSTEMD_USER_SERVICE" ]; then
        systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
    fi

    local pids
    pids="$(pgrep -f "${XRAY_BIN}" 2>/dev/null || true)"
    if [ -n "$pids" ]; then
        kill -9 $pids 2>/dev/null || true
        echo -e "${C_GREEN}[✓] Stopped all Xray processes.${C_RESET}"
    else
        echo -e "${C_YELLOW}No active Xray processes found.${C_RESET}"
    fi

    pause
}

# Main Loop
main_menu() {
    while true; do
        show_header
        echo -e "${C_GRAY}Please select an option:${C_RESET}"
        echo -e "  ${C_CYAN}[1]${C_RESET} Start Xray in this terminal (Foreground)"
        echo -e "  ${C_GREEN}[2]${C_RESET} Install / Start Systemd Service (Auto-start on boot/login)"
        echo -e "  ${C_YELLOW}[3]${C_RESET} Stop & Remove Systemd Service"
        echo -e "  ${C_MAGENTA}[4]${C_RESET} Download / Update latest Xray-core from GitHub"
        echo -e "  ${C_RED}[5]${C_RESET} Stop all running Xray instances"
        echo -e "  ${C_DGRAY}[0] Exit${C_RESET}"
        echo ""
        read -r -p "Enter option [0-5]: " choice

        case "$choice" in
            1) start_foreground ;;
            2) setup_systemd_service ;;
            3) remove_systemd_service ;;
            4) download_xray ;;
            5) stop_all ;;
            0) 
                clear
                exit 0 
                ;;
            *)
                echo -e "${C_RED}Invalid choice, please select 0 to 5.${C_RESET}"
                sleep 1
                ;;
        esac
    done
}

main_menu
