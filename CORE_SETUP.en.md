# Core Setup & Service Guide

This guide details target address configuration, downloading Xray-core, live execution, and background autostart service registration.

> 📖 **[راهنمای فارسی: CORE_SETUP.md](CORE_SETUP.md)** | 🌐 **[Back to Main README](README.en.md)**

---

## ⚙️ Step 1: Configure Target Address

Open [config.json](config.json) in your editor and specify your upstream/CDN IP and port under `outbounds -> settings -> redirect`:

```json
"settings": {
  "redirect": "188.114.97.6:443"
}
```

---

## 🖥️ Running by Operating System

### Windows (Native TUI)

1. Double-click [menu.bat](menu.bat) (or run [menu.ps1](menu.ps1) in PowerShell).
2. Choose **Option [4]** to automatically download and extract the latest compatible **Xray-core**.
3. Next:
   - **Foreground run:** Select **Option [1]** to test in terminal.
   - **Background Startup:** Select **Option [2]** to register as a Windows Task Scheduler autostart service.

### Linux (Native TUI)

Open your terminal in the repository folder and execute:
```bash
chmod +x menu.sh
./menu.sh
```
1. Select **Option [4]** to automatically detect your architecture (`x86_64`, `arm64`, `armv7`) and download the core binary.
2. Next:
   - **Foreground run:** Select **Option [1]**.
   - **Permanent systemd service:** Select **Option [2]** (supports system service with root, or user-level service without root).

### Docker Compose

For containerized deployment on any OS:
```bash
docker compose up -d
```

---

## 🔄 Manual Background Service Management

### Windows (PowerShell):
- **Start task:** `Start-ScheduledTask -TaskName "XrayFragment"`
- **Stop task:** `Stop-ScheduledTask -TaskName "XrayFragment"` and `taskkill /F /IM xray.exe`
- **Remove from startup:** `Unregister-ScheduledTask -TaskName "XrayFragment" -Confirm:$false`

### Linux (systemd):
- **System service:** `sudo systemctl [start|stop|status|restart] xray-fragment`
- **User service:** `systemctl --user [start|stop|status|restart] xray-fragment`
