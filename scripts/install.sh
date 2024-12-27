#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Temporary directory for downloads
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Detect system information
detect_system() {
    local os arch suffix

    case "$(uname -s)" in
        Linux*)  os="linux";;
        Darwin*) os="darwin";;
        *)       echo "Unsupported OS"; exit 1;;
    esac

    case "$(uname -m)" in
        x86_64)  
            arch="x64"
            [ "$os" = "darwin" ] && suffix="_intel"
            ;;
        aarch64|arm64) 
            arch="arm64"
            [ "$os" = "darwin" ] && suffix="_apple_silicon"
            ;;
        *)       echo "Unsupported architecture"; exit 1;;
    esac

    echo "$os $arch $suffix"
}

# Download with progress using curl or wget
download() {
    local url="$1"
    local output="$2"
    
    if command -v curl >/dev/null 2>&1; then
        curl -#L "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget --show-progress -q "$url" -O "$output"
    else
        echo "Error: curl or wget is required"
        exit 1
    fi
}

# Check and create installation directory
setup_install_dir() {
    local install_dir="$1"
    
    if [ ! -d "$install_dir" ]; then
        mkdir -p "$install_dir" || {
            echo "Failed to create installation directory"
            exit 1
        }
    fi
}

# Main installation function
main() {
    echo -e "${BLUE}Starting installation...${NC}"
    
    # Detect system
    read -r OS ARCH SUFFIX <<< "$(detect_system)"
    echo -e "${GREEN}Detected: $OS $ARCH${NC}"
    
    # Set installation directory
    INSTALL_DIR="/usr/local/bin"
    [ "$OS" = "darwin" ] && INSTALL_DIR="/usr/local/bin"
    
    # Setup installation directory
    setup_install_dir "$INSTALL_DIR"
    
    # Download latest release
    LATEST_URL="https://api.github.com/repos/dacrab/go-cursor-help/releases/latest"
    BINARY_NAME="cursor-id-modifier_${OS}_${ARCH}${SUFFIX}"
    DOWNLOAD_URL=$(curl -s "$LATEST_URL" | grep "browser_download_url.*${BINARY_NAME}" | cut -d '"' -f 4)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${RED}Error: Could not find download URL for $OS $ARCH${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Downloading latest release...${NC}"
    download "$DOWNLOAD_URL" "$TMP_DIR/cursor-id-modifier"
    
    # Install binary
    echo -e "${BLUE}Installing...${NC}"
    chmod +x "$TMP_DIR/cursor-id-modifier"
    sudo mv "$TMP_DIR/cursor-id-modifier" "$INSTALL_DIR/"
    
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "${BLUE}Running cursor-id-modifier...${NC}"
    
    # Run the program
    export AUTOMATED_MODE=1
    if ! cursor-id-modifier; then
        echo -e "${RED}Failed to run cursor-id-modifier${NC}"
        exit 1
    fi
}

main
