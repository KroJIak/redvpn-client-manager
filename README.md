
[English](README.md) | [Русский](docs/README-RU.md)

<div align="center">

![RedVPN](https://img.shields.io/badge/RedVPN-Client%20Manager-red?style=for-the-badge&logo=shield&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![sing-box](https://img.shields.io/badge/sing--box-VPN-00B8D4?style=for-the-badge&logo=shield&logoColor=white)
![systemd](https://img.shields.io/badge/systemd-service-DA2525?style=for-the-badge&logo=linux&logoColor=white)
![Debian](https://img.shields.io/badge/Debian%20%7C%20Ubuntu-ready-A81D33?style=for-the-badge&logo=debian&logoColor=white)

</div>

# RedVPN Client Manager

> Client manager for RedVPN provider with ssconf protocol support. Provides easy VPN connection and management through sing-box on Debian/Ubuntu systems.

---

## Table of Contents

- [Description](#description)
- [Features](#features)
- [Requirements](#requirements)
- [Quick Installation](#quick-installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Frequently Asked Questions](#frequently-asked-questions)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Description

**RedVPN Client Manager** is a client manager for the **RedVPN** VPN provider. The project provides a convenient way to connect and manage VPN connections through the **ssconf** protocol using **sing-box** on Debian/Ubuntu systems.

### Key Advantages:

- **Security**: Uses proven sing-box for tunneling
- **Simplicity**: One script for complete RedVPN setup
- **Speed**: Automatic configuration retrieval from RedVPN server
- **Convenience**: CLI interface for VPN management
- **Automation**: Integration with systemd for autostart
- **Reliability**: Dependency checking and ssconf key validation

---

## Features

### Automatic Installation
- Check and install all required dependencies for Debian/Ubuntu
- Automatic systemd service setup for RedVPN
- polkit configuration for management without sudo

### Convenient Management
- Simple CLI commands (`redvpn start/stop/status`)
- Custom Command Toggle integration
- Display current IP address through RedVPN

### Dynamic Configuration
- Automatic retrieval of RedVPN server parameters via API
- sing-box configuration update on each startup
- RedVPN ssconf protocol support

---

## Requirements

### System Requirements
- **OS**: Debian 10+ or Ubuntu 18.04+
- **Architecture**: x86_64, ARM64
- **Permissions**: sudo access for installation
- **VPN**: Active RedVPN subscription with ssconf key

### Dependencies
- `curl` - for downloads and API requests
- `jq` - for parsing JSON responses
- `sing-box` - VPN client (installed automatically)

---

## Quick Installation

### 1. Clone Repository
```bash
git clone https://github.com/KroJIak/redvpn-client-manager.git
cd redvpn-client-manager
```

### 2. Run Installer
```bash
bash install.sh [--debug] [--quiet] [--skip-key-input]
```

### 3. Enter ssconf Key
```
Enter your RedVPN ssconf key:
Format: ssconf://red.alfanw.net/key/YOUR_KEY#RedVPN
```

> **Note**: ssconf key is provided by RedVPN provider when purchasing a subscription

### Installer Flags

- `--debug` - hide detailed command output
- `--quiet` - no normal logs (errors still shown)
- `--skip-key-input` - use existing key from `~/.config/redvpn/redvpn.conf`

## Usage

### Basic Commands

```bash
# Start VPN
redvpn start

# Stop VPN  
redvpn stop

# Check status
redvpn status

# Restart VPN
redvpn restart

# Show help
redvpn help
```

## Configuration

### Configuration Structure

```
~/.config/redvpn/
├── redvpn.conf          # Main configuration
└── ...

~/.config/sing-box/
└── redvpn.json          # sing-box configuration (auto-generated)
```

### Configuration File

`~/.config/redvpn/redvpn.conf`:
```bash
# RedVPN Configuration
SSCONF='ssconf://red.alfanw.net/key/YOUR_KEY#RedVPN'
```

### sing-box Configuration

The `~/.config/sing-box/redvpn.json` file is automatically created on each startup:

```json
{
  "log": { "level": "info" },
  "inbounds": [
    { 
      "type": "tun", 
      "interface_name": "redvpn-tun0",
      "address": ["172.19.0.1/30"],
      "auto_route": true, 
      "strict_route": false,
      "sniff": true,
      "stack": "system" 
    }
  ],
  "outbounds": [
    { 
      "type": "shadowsocks",
      "tag": "proxy",
      "method": "chacha20-ietf-poly1305",
      "password": "your-password",
      "server": "your-server.com",
      "server_port": 443
    },
    { 
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "auto_detect_interface": true,
    "final": "proxy",
    "rules": [
      { "protocol": "dns", "outbound": "direct" },
      { "ip_cidr": ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.0/8"], "outbound": "direct" }
    ]
  }
}
```

---

### How to Change ssconf Key?

Edit the file `~/.config/redvpn/redvpn.conf`:
```bash
nano ~/.config/redvpn/redvpn.conf
```

### How to Uninstall RedVPN?

```bash
# Stop service
systemctl --user stop redvpn.service

# Remove files
sudo rm -f /usr/local/bin/redvpn
sudo rm -f /usr/local/bin/redvpn-update
sudo rm -f /etc/systemd/system/redvpn.service
sudo rm -f /etc/sudoers.d/redvpn-*
sudo rm -f /etc/polkit-1/rules.d/50-redvpn.rules

# Remove configuration
rm -rf ~/.config/redvpn
rm -rf ~/.config/sing-box

# Reload systemd
sudo systemctl daemon-reload
```

### Are Other VPN Protocols Supported?

This client manager is designed exclusively for the **RedVPN** VPN provider and supports only the ssconf protocol through sing-box. For other VPN providers, use the appropriate clients.

---

## Troubleshooting

### Error: "Failed to get response from server"

**Causes:**
- Server unavailable
- Invalid ssconf key
- Domain blocked by ISP

**Solution:**
```bash
# Check server availability
curl -I https://red.alfanw.net

# Check key format
cat ~/.config/redvpn/redvpn.conf
```

### Error: "Permission denied"

**Causes:**
- Incorrect permissions
- polkit issues

**Solution:**
```bash
# Reboot system
sudo reboot

# Or update groups
newgrp systemd-journal
```

### Error: "sing-box not found"

**Causes:**
- sing-box not installed
- PATH issues

**Solution:**
```bash
# Reinstall sing-box
curl -fsSL https://sing-box.app/install.sh | sh

# Check installation
which sing-box
```

### VPN Not Connecting

**Diagnostics:**
```bash
# Check service status
systemctl --user status redvpn.service

# Check logs
journalctl --user -u redvpn.service -f

# Check configuration
cat ~/.config/sing-box/redvpn.json
```

### Routing Issues

**Solution:**
```bash
# Check routing table
ip route show

# Check network interfaces
ip addr show
```

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Made for RedVPN users on Debian/Ubuntu**

</div>
