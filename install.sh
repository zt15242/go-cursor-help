#!/usr/bin/env bash

# Error handling
error() {
    echo -e "\033[31m\033[1mError:\033[0m $1" >&2
    exit 1
}

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Get latest version
VERSION=$(curl -sL "https://api.github.com/repos/realies/go-cursor-help/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
[ -z "$VERSION" ] && error "Could not determine latest version"

# Get binary name based on platform
case "$OS" in
    linux*)
        case "$ARCH" in
            x86_64)  BINARY="cursor_id_modifier_${VERSION}_linux_amd64" ;;
            aarch64|arm64) BINARY="cursor_id_modifier_${VERSION}_linux_arm64" ;;
            *) error "Unsupported Linux architecture: $ARCH" ;;
        esac
        ;;
    darwin*)
        case "$ARCH" in
            x86_64) BINARY="cursor_id_modifier_${VERSION}_darwin_amd64" ;;
            arm64)  BINARY="cursor_id_modifier_${VERSION}_darwin_arm64" ;;
            *) error "Unsupported macOS architecture: $ARCH" ;;
        esac
        ;;
    *) error "Unsupported operating system: $OS" ;;
esac

# Set up cleanup trap
trap 'rm -f "./${BINARY}"' EXIT

# Download and run
DOWNLOAD_URL="https://github.com/realies/go-cursor-help/releases/download/v${VERSION}/${BINARY}"
echo "Downloading from: ${DOWNLOAD_URL}"

# Download with error checking
if ! curl -fL "$DOWNLOAD_URL" -o "./${BINARY}"; then
    error "Download failed. HTTP error from GitHub"
fi

chmod +x "./${BINARY}"
echo "Running cursor-id-modifier..."
sudo "./${BINARY}"
