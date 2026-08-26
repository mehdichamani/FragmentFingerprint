# Fragment Fingerprint

A local MitM relay and DPI / censorship / sanction bypass solution powered by **Xray-core** (version `26.7.28`+) using advanced TCP/TLS Hello packet fragmentation and pinned certificate fingerprinting (**Certificate SHA-256 Pinning**).

> 📖 **[مستندات فارسی (README.md)](README.md)**

---

## 🎯 How It Works

Censorship and DPI systems scan and block `TLS Client Hello` packets to detect domains and protocols (such as VLESS / Trojan over TLS). Additionally, various foreign services like Antigravity impose geographical blocks.

This project creates a local/network proxy that intercepts client traffic, matches it using a pinned secure certificate, and sends the outgoing traffic fragmented with configured lengths and delays to bypass detection.

```text
[ Client (PattN / v2rayN / V2Box / ...) ]
                   │
                   ▼ (Pinned TLS connection to 127.0.0.1:40443)
        [ Project Xray Core ]
                   │
                   ▼ (Fragment technique + customized TLS to upstream server)
[ Target Server / CDN / Upstream IP (e.g. 188.114.97.6:443) ]
```

---

## 📚 Guides & Documentation

Follow the dedicated guides below for setup and client usage:

- ⚙️ **[Core Setup & Service Management (Windows, Linux, Docker)](CORE_SETUP.en.md)**
- 🛡️ **[Client Configuration & Antigravity Bypass Guide](CLIENT_CONFIG.en.md)**

---

## 👥 Credits & Acknowledgements

The original idea and design were created by **[@patterniha](https://t.me/patterniha)**.  
This repository was developed solely for **easy implementation, full automation, and cross-platform service management**.

- **Designer Telegram:** [@patterniha](https://t.me/patterniha)
- **Recommended Clients:** [PattN](https://github.com/patterniha/PattN) / [v2rayN](https://github.com/2dust/v2rayN)
