# Running as Background Service & Startup - Guide

This document explains how background execution and automatic startup work across Windows and Linux.

---

## 🐧 Linux Service & Startup (systemd)

On Linux, the easiest way to install and manage the background service is using the built-in TUI:
```bash
./menu.sh
```
Select **Option [2]** to install the systemd service.

### 1. System Service (with `sudo` / `root`)
- **Location:** `/etc/systemd/system/xray-fragment.service`
- **Commands:**
  ```bash
  sudo systemctl start xray-fragment     # Start
  sudo systemctl stop xray-fragment      # Stop
  sudo systemctl status xray-fragment    # Status
  sudo systemctl enable xray-fragment    # Enable on boot
  sudo systemctl disable xray-fragment   # Disable on boot
  ```

### 2. User Service (Non-root fallback)
- **Location:** `~/.config/systemd/user/xray-fragment.service`
- **Commands:**
  ```bash
  systemctl --user start xray-fragment
  systemctl --user stop xray-fragment
  systemctl --user status xray-fragment
  systemctl --user enable xray-fragment
  ```
- **Enable lingering (runs without active terminal session):**
  ```bash
  loginctl enable-linger $USER
  ```

---

## 🖥️ Windows Service & Startup (Task Scheduler)

On Windows, run [menu.bat](menu.bat) and select **Option [2]** to automatically configure Windows Task Scheduler for silent startup on login.

### Manual PowerShell Management
- **Start background task:**
  ```powershell
  Start-ScheduledTask -TaskName "XrayFragment"
  ```
- **Stop background task & kill process:**
  ```powershell
  Stop-ScheduledTask -TaskName "XrayFragment"
  taskkill /F /IM xray.exe
  ```
- **Remove from startup:**
  ```powershell
  Unregister-ScheduledTask -TaskName "XrayFragment" -Confirm:$false
  ```
