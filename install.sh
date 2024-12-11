#!/bin/bash

# Error handling function / 错误处理函数
error() {
    echo "Error/错误: $1" >&2
    exit 1
}

# Detect OS and architecture / 检测操作系统和架构
detect_platform() {
    # Get lowercase OS name and architecture / 获取小写操作系统名称和架构
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    # Set binary name based on platform / 根据平台设置二进制文件名
    case "$OS" in
        linux*)
            case "$ARCH" in
                x86_64)  BINARY_NAME="cursor_id_modifier_v2.0.0_linux_amd64" ;;
                *) error "Unsupported Linux architecture/不支持的Linux架构: $ARCH" ;;
            esac
            ;;
        darwin*)
            case "$ARCH" in
                x86_64) BINARY_NAME="cursor_id_modifier_v2.0.0_mac_intel" ;;
                arm64)  BINARY_NAME="cursor_id_modifier_v2.0.0_mac_m1" ;;
                *) error "Unsupported macOS architecture/不支持的macOS架构: $ARCH" ;;
            esac
            ;;
        *)
            error "Unsupported operating system/不支持的操作系统: $OS"
            ;;
    esac
}

# Check root privileges / 检查root权限
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run with sudo or as root/此脚本必须使用sudo或root权限运行"
fi

# Initialize installation / 初始化安装
detect_platform
INSTALL_DIR="/usr/local/bin"
[ -d "$INSTALL_DIR" ] || mkdir -p "$INSTALL_DIR"

# Download binary / 下载二进制文件
echo "Downloading cursor-id-modifier for/正在下载 $OS ($ARCH)..."
TEMP_DIR=$(mktemp -d)
DOWNLOAD_URL="https://github.com/yuaotian/go-cursor-help/raw/main/bin/$BINARY_NAME"

if ! curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_DIR/$BINARY_NAME"; then
    error "Failed to download binary/下载二进制文件失败"
fi

# Set permissions / 设置权限
if ! chmod +x "$TEMP_DIR/$BINARY_NAME"; then
    error "Failed to make binary executable/无法设置可执行权限"
fi

# Handle macOS security / 处理macOS安全设置
if [ "$OS" = "darwin" ]; then
    echo "Removing macOS quarantine attribute/移除macOS隔离属性..."
    xattr -d com.apple.quarantine "$TEMP_DIR/$BINARY_NAME" 2>/dev/null || true
fi

# Install binary / 安装二进制文件
if ! mv "$TEMP_DIR/$BINARY_NAME" "$INSTALL_DIR/cursor-id-modifier"; then
    error "Failed to install binary/安装二进制文件失败"
fi

# Cleanup / 清理
rm -rf "$TEMP_DIR"

echo "✅ Installation successful! You can now run 'cursor-id-modifier' from anywhere."
echo "✅ 安装成功！现在可以在任何位置运行 'cursor-id-modifier'。"