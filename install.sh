#!/usr/bin/env bash
set -euo pipefail

echo "RedVPN Quick Start Button Installer"
echo "===================================="

# Check and install required dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if ! command -v sing-box &> /dev/null; then
        missing_deps+=("sing-box")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Missing dependencies detected:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Starting installation..."
        
        # Update packages
        echo "Updating package list..."
        sudo apt update
        
        # Install curl and jq via apt
        if [[ " ${missing_deps[@]} " =~ " curl " ]]; then
            echo "Installing curl..."
            sudo apt install -y curl
        fi
        
        if [[ " ${missing_deps[@]} " =~ " jq " ]]; then
            echo "Installing jq..."
            sudo apt install -y jq
        fi
        
        # Install sing-box via official script
        if [[ " ${missing_deps[@]} " =~ " sing-box " ]]; then
            echo "Installing sing-box..."
            curl -fsSL https://sing-box.app/install.sh | sh
        fi
        
        echo ""
        echo "Dependencies installation completed!"
        echo ""
    fi
}

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
        return 1
    fi
    
    return 0
}

# Main function
main() {
    echo "Checking and installing dependencies..."
    check_dependencies
    echo "✓ Dependencies checked"
    
    echo ""
    echo "Enter your RedVPN ssconf key:"
    echo "Format: ssconf://red.alfanw.net/key/YOUR_KEY#RedVPN"
    echo ""
    
    # Check if stdin is available for reading
    if [ ! -t 0 ]; then
        echo "Error: No access to stdin for key input"
        echo "Run the script interactively: bash install.sh"
        exit 1
    fi
    
    echo -n "ssconf key: "
    read -r ssconf_key
    
    # Validate key
    if ! validate_ssconf_key "$ssconf_key"; then
        exit 1
    fi
    
    echo "✓ Key accepted: ${ssconf_key:0:20}..."
    
    echo ""
    echo "Starting RedVPN setup..."
    echo "=========================="
    
    # Run setup.sh with key passed
    bash "$(dirname "$0")/redvpn/setup.sh" "$ssconf_key"
    
    echo ""
    echo "Installation completed!"
    echo "You can now add command to Custom Command Toggle:"
    echo "  Start VPN: systemctl --user start redvpn.service"
    echo "  Stop VPN: systemctl --user stop redvpn.service"
    echo "  VPN Status: systemctl --user is-active redvpn.service"
}

main "$@"