#!/bin/bash

# Version / 版本号
VERSION="v2.0.0"

# Bilingual message functions / 双语消息函数
error() {
    echo "❌ Error: $1"
    echo "❌ 错误：$2"
    exit 1
}

info() {
    echo "ℹ️ $1"
    echo "ℹ️ $2"
}

success() {
    echo "✅ $1"
    echo "✅ $2"
}

# Detect OS and architecture / 检测操作系统和架构
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$OS" in
        linux*)
            case "$ARCH" in
                x86_64)  BINARY_NAME="cursor_id_modifier_${VERSION}_linux_amd64" ;;
                *) error "Unsupported Linux architecture: $ARCH" "不支持的Linux架构：$ARCH" ;;
            esac
            ;;
        darwin*)
            case "$ARCH" in
                x86_64) BINARY_NAME="cursor_id_modifier_${VERSION}_darwin_amd64_intel" ;;
                arm64)  BINARY_NAME="cursor_id_modifier_${VERSION}_darwin_arm64_m1" ;;
                *) error "Unsupported macOS architecture: $ARCH" "不支持的macOS架构：$ARCH" ;;
            esac
            ;;
        msys*|mingw*|cygwin*)
            case "$ARCH" in
                x86_64) BINARY_NAME="cursor_id_modifier_${VERSION}_windows_amd64.exe" ;;
                *) error "Unsupported Windows architecture: $ARCH" "不支持的Windows架构：$ARCH" ;;
            esac
            ;;
        *)
            error "Unsupported operating system: $OS" "不支持的操作系统：$OS"
            ;;
    esac
}

# Check system requirements / 检查系统要求
check_requirements() {
    info "Checking system requirements..." "正在检查系统要求..."
    
    # Check curl
    if ! command -v curl >/dev/null 2>&1; then
        error "curl is required. Please install curl first." \
              "需要安装 curl。请先安装 curl 后再运行此脚本。"
    fi
    
    # Check write permissions / 检查写入权限
    if [ ! -w "$INSTALL_DIR" ]; then
        error "No write permission for $INSTALL_DIR. Please run with sudo." \
              "没有 $INSTALL_DIR 的写入权限。请使用 sudo 运行此脚本。"
    fi
}

# Verify binary / 验证二进制文件
verify_binary() {
    info "Verifying binary..." "正在验证二进制文件..."
    if [ ! -f "$TEMP_DIR/$BINARY_NAME" ]; then
        error "Binary file download failed or does not exist" \
              "二进制文件下载失败或不存在"
    fi
    
    # Check file size / 检查文件大小
    local size=$(wc -c < "$TEMP_DIR/$BINARY_NAME")
    if [ "$size" -lt 1000000 ]; then  # At least 1MB / 至少1MB
        error "Downloaded file size is abnormal, download might be incomplete" \
              "下载的文件大小异常，可能下载不完整"
    fi
}

# Main installation process / 主安装流程
main() {
    info "Starting installation of cursor-id-modifier ${VERSION}..." \
         "开始安装 cursor-id-modifier ${VERSION}..."
    
    # Initialize installation / 初始化安装
    detect_platform
    INSTALL_DIR="/usr/local/bin"
    [ -d "$INSTALL_DIR" ] || mkdir -p "$INSTALL_DIR"
    
    # Check requirements / 检查要求
    check_requirements
    
    # Create temp directory / 创建临时目录
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT
    
    # Download binary / 下载二进制文件
    info "Downloading cursor-id-modifier ($OS-$ARCH)..." \
         "正在下载 cursor-id-modifier ($OS-$ARCH)..."
    DOWNLOAD_URL="https://github.com/yuaotian/go-cursor-help/raw/main/bin/$BINARY_NAME"
    
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_DIR/$BINARY_NAME"; then
        error "Failed to download binary" "下载二进制文件失败"
    fi
    
    # Verify download / 验证下载
    verify_binary
    
    # Set permissions / 设置权限
    info "Setting execution permissions..." "正在设置执行权限..."
    if ! chmod +x "$TEMP_DIR/$BINARY_NAME"; then
        error "Failed to set executable permissions" "无法设置可执行权���"
    fi
    
    # Handle macOS security / 处理macOS安全设置
    if [ "$OS" = "darwin" ]; then
        info "Handling macOS security settings..." "正在处理macOS安全设置..."
        xattr -d com.apple.quarantine "$TEMP_DIR/$BINARY_NAME" 2>/dev/null || true
    fi
    
    # Install binary / 安装二进制文件
    info "Installing binary..." "正在安装二进制文件..."
    if ! mv "$TEMP_DIR/$BINARY_NAME" "$INSTALL_DIR/cursor-id-modifier"; then
        error "Failed to install binary" "安装二进制文件失败"
    fi
    
    success "Installation successful! You can now run 'cursor-id-modifier' from anywhere." \
            "安装成功！现在可以在任何位置运行 'cursor-id-modifier'。"
    success "For help, run 'cursor-id-modifier --help'" \
            "如需帮助，请运行 'cursor-id-modifier --help'"
}

# Start installation / 开始安装
main