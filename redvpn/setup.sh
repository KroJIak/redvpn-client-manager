#!/usr/bin/env bash
set -euo pipefail

# Validate ssconf key format
validate_ssconf_key() {
    local key="$1"
    
    if [ -z "$key" ]; then
        echo "Error: Key cannot be empty!"
        return 1
    fi
    
    if [[ ! "$key" =~ ^ssconf:// ]]; then
        echo "Error: Invalid ssconf key format!"
        echo "Received key: '$key'"
        echo "Expected format: ssconf://red.alfanw.net/key/YOUR_KEY#RedVPN"
        return 1
    fi
    
    return 0
}

# Check if ssconf key is provided
if [ $# -ne 1 ]; then
    echo "Error: ssconf key must be provided as argument"
    echo "Usage: $0 <ssconf_key>"
    exit 1
fi

SSCONF_KEY="$1"

# Validate key format
if ! validate_ssconf_key "$SSCONF_KEY"; then
    exit 1
fi

echo "Setting up RedVPN..."
echo "==================="

# Create necessary directories
echo "Creating directories..."
mkdir -p "$HOME/.config/redvpn"
mkdir -p "$HOME/.config/sing-box"

# Save key to redvpn.conf
echo "Saving ssconf key..."
cat > "$HOME/.config/redvpn/redvpn.conf" << EOF
# RedVPN Configuration
SSCONF='$SSCONF_KEY'
EOF

echo "Key saved to $HOME/.config/redvpn/redvpn.conf"

# Copy redvpn-update
echo "Copying redvpn-update..."
SCRIPT_DIR="$(dirname "$0")"

# Copy redvpn-update to /usr/local/bin/
echo "Copying redvpn-update to /usr/local/bin/..."
if [ -f "$SCRIPT_DIR/redvpn-update" ]; then
	sudo cp "$SCRIPT_DIR/redvpn-update" "/usr/local/bin/redvpn-update"
	sudo chmod +x "/usr/local/bin/redvpn-update"
else
	echo "Error: redvpn-update not found in $SCRIPT_DIR"
	exit 1
fi

# Copy redvpn CLI to /usr/local/bin/
echo "Copying redvpn CLI to /usr/local/bin/..."
if [ -f "$SCRIPT_DIR/redvpn" ]; then
	sudo cp "$SCRIPT_DIR/redvpn" "/usr/local/bin/redvpn"
	sudo chmod +x "/usr/local/bin/redvpn"
else
	echo "Error: redvpn not found in $SCRIPT_DIR"
	exit 1
fi

# Copy redvpn.service to /etc/systemd/system/ with placeholder replacement
echo "Copying systemd service..."
CURRENT_USER="$(whoami)"
CURRENT_GROUP="$(id -gn)"
sed "s/__USER__/$CURRENT_USER/g; s/__GROUP__/$CURRENT_GROUP/g; s|__HOME__|$HOME|g" "$SCRIPT_DIR/redvpn.service" | sudo tee "/etc/systemd/system/redvpn.service" > /dev/null

# Reload systemd (do NOT enable autostart)
echo "Configuring systemd service..."
sudo systemctl daemon-reload
# Service is NOT enabled for autostart - only on user request

# Configure sudo without password for redvpn systemctl commands
echo "Configuring sudo without password for redvpn commands..."
SUDOERS_RULE="$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/local/bin/redvpn"
echo "$SUDOERS_RULE" | sudo tee "/etc/sudoers.d/redvpn-$CURRENT_USER" > /dev/null
sudo chmod 440 "/etc/sudoers.d/redvpn-$CURRENT_USER"

# Add user to systemd-journal group for service management
echo "Adding user to systemd-journal group..."
sudo usermod -a -G systemd-journal "$CURRENT_USER"

# Remove old polkit rules
echo "Cleaning up old polkit rules..."
sudo rm -f "/etc/polkit-1/localauthority/50-local.d/50-redvpn.pkla"
sudo rm -f "/etc/polkit-1/localauthority/50-local.d/51-redvpn-service.pkla"
sudo rm -f "/etc/polkit-1/rules.d/50-redvpn.rules"

# Create simple and effective polkit rule
echo "Creating polkit rule for redvpn..."
sudo mkdir -p "/etc/polkit-1/rules.d"
sudo tee "/etc/polkit-1/rules.d/50-redvpn.rules" > /dev/null << EOF
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        subject.user == "$CURRENT_USER" &&
        (action.lookup("unit") == "redvpn.service" || 
         action.lookup("unit") == "redvpn")) {
        return polkit.Result.YES;
    }
});
EOF

echo ""
echo "Setup completed!"
echo "===================="
echo "RedVPN service configured."
echo ""
echo "⚠️  IMPORTANT: To apply changes in groups and polkit:"
echo "   1. Reboot the system OR"
echo "   2. Run: newgrp systemd-journal"
echo "   3. Restart session (logout/login)"
echo ""
echo "Available commands:"
echo "  redvpn start   - Start VPN"
echo "  redvpn stop    - Stop VPN"
echo "  redvpn status  - Show VPN status"
echo "  redvpn restart - Restart VPN"
echo ""
echo "For Custom Command Toggle use:"
echo "  Toggle Command:   redvpn start"
echo "  Untoggle Command: redvpn stop"
echo "  Status Command:   redvpn status"