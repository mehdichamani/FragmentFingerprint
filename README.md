# Fragment Fingerprint

A local MitM relay and DPI bypass solution powered by **Xray-core** using advanced TCP/TLS Hello packet fragmentation and pinned certificate fingerprinting.

📖 **[راهنمای فارسی (Persian README)](README.fa.md)**

---

## Features & Entry Points

- **🖥️ Windows Native TUI:** Run [menu.bat](menu.bat) to download Xray-core, run in foreground, or register as a background Task Scheduler auto-start.
- **🐧 Linux Native TUI:** Run `./menu.sh` to download the architecture-matching binary (`x86_64`, `arm64`, `armv7`), run foreground, or manage system/user `systemd` auto-start services.
- **🐳 Docker Compose:** Run `docker compose up -d` using [compose.yml](compose.yml) on any OS with Docker.

---

## Quick Start

1. **Configure Target:** Edit [config.json](config.json) and replace `"redirect": "188.114.97.6:443"` with your target server/CDN IP and port.
2. **Run by Method:**
   - **Linux:**
     ```bash
     chmod +x menu.sh
     ./menu.sh
     ```
   - **Windows:** Double-click [menu.bat](menu.bat) or execute:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\menu.ps1
     ```
   - **Docker (Windows / Linux):**
     ```bash
     docker compose up -d
     ```
3. **Client Configuration:** Point your VLESS/Trojan/TLS client to:
   - **Address:** `127.0.0.1` (or local LAN IP)
   - **Port:** `40443`
   - **Pinned Certificate SHA-256:** `3de5b7bd48c18c9ff057d8961f24c16555a7e387ebb509e1efb1315303695c82`

---

## Credits & Donation

- **Creator:** [@patterniha](https://t.me/patterniha)
- **USDT (BEP20):** `0x76a768B53Ca77B43086946315f0BDF21156bF424`
- **USDT (TRC20):** `TU5gKvKqcXPn8itp1DouBCwcqGHMemBm8o`
- **TON:** `UQAc-mZB3y7uxWHKiMmq0ORZEYgycWDWZ4V1k73HsXvTJx-i`
