#!/usr/bin/env bash
set -euo pipefail

quiet=0
debug=0
skip_key_input=0

usage() {
    cat <<'EOF'
Usage: bash install.sh [--debug] [--quiet] [--skip-key-input]

  --debug            Hide detailed command output
  --quiet            No normal logs (errors still shown)
  --skip-key-input   Use existing key from ~/.config/redvpn/redvpn.conf
EOF
}

log() {
    if [ $quiet -eq 0 ]; then
        echo "$@"
    fi
}

run_cmd() {
    if [ $quiet -eq 1 ]; then
        "$@" >/dev/null 2>&1
    elif [ $debug -eq 1 ]; then
        "$@" >/dev/null
    else
        "$@"
    fi
}

run_pipe() {
    if [ $quiet -eq 1 ]; then
        bash -c "$1" >/dev/null 2>&1
    elif [ $debug -eq 1 ]; then
        bash -c "$1" >/dev/null
    else
        bash -c "$1"
    fi
}

while [ $# -gt 0 ]; do
    case "$1" in
        --debug)
            debug=1
            ;;
        --quiet)
            quiet=1
            ;;
        --skip-key-input)
            skip_key_input=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

log "RedVPN Quick Start Button Installer"

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
        log "Missing dependencies detected:"
        for dep in "${missing_deps[@]}"; do
            log "  - $dep"
        done
        log ""
        log "Starting installation..."
        
        # Update packages
        log "Updating package list..."
        run_cmd sudo apt update
        
        # Install curl and jq via apt
        if [[ " ${missing_deps[@]} " =~ " curl " ]]; then
            log "Installing curl..."
            run_cmd sudo apt install -y curl
        fi
        
        if [[ " ${missing_deps[@]} " =~ " jq " ]]; then
            log "Installing jq..."
            run_cmd sudo apt install -y jq
        fi
        
        # Install sing-box via official script
        if [[ " ${missing_deps[@]} " =~ " sing-box " ]]; then
            log "Installing sing-box..."
            run_pipe "curl -fsSL https://sing-box.app/install.sh | sh"
        fi
        
        log ""
        log "Dependencies installation completed!"
        log ""
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
    log "Checking and installing dependencies..."
    check_dependencies
    log "✓ Dependencies checked"

    ssconf_key=""

    if [ $skip_key_input -eq 1 ]; then
        config_file="$HOME/.config/redvpn/redvpn.conf"
        if [ ! -f "$config_file" ]; then
            echo "Error: $config_file not found. Cannot skip key input." >&2
            exit 1
        fi

        ssconf_key="$(awk -F"'" '/^SSCONF=/{print $2}' "$config_file" | head -n 1)"
        if [ -z "$ssconf_key" ]; then
            echo "Error: SSCONF not found in $config_file." >&2
            exit 1
        fi
    else
        log ""
        log "Enter your RedVPN ssconf key:"
        log "Format: ssconf://red.alfanw.net/key/YOUR_KEY#RedVPN"
        log ""
        
        # Check if stdin is available for reading
        if [ ! -t 0 ]; then
            echo "Error: No access to stdin for key input" >&2
            echo "Run the script interactively or use --skip-key-input" >&2
            exit 1
        fi
        
        echo -n "ssconf key: "
        read -r ssconf_key
    fi
    
    # Validate key
    if ! validate_ssconf_key "$ssconf_key"; then
        exit 1
    fi
    
    log "✓ Key accepted: ${ssconf_key:0:20}..."
    
    log ""
    log "Starting RedVPN setup..."
    
    # Run setup.sh with key passed
    run_cmd bash "$(dirname "$0")/redvpn/setup.sh" "$ssconf_key"
    
    log ""
    log "Installation completed!"
    log "You can now add command to Custom Command Toggle:"
    log "  Start VPN: systemctl --user start redvpn.service"
    log "  Stop VPN: systemctl --user stop redvpn.service"
    log "  VPN Status: systemctl --user is-active redvpn.service"
}

main "$@"