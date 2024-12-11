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
    
    # 添加网络连接检查
    if ! ping -c 1 github.com >/dev/null 2>&1; then
        error "No network connection to GitHub" \
              "无法连接到 GitHub"
    fi
    
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
    if [ ! -f "$DOWNLOAD_PATH" ]; then
        error "Binary file download failed or does not exist" \
              "二进制文件下载失败或不存在"
    fi
    
    # 添加可执行文件格式检查
    if ! file "$DOWNLOAD_PATH" | grep -q "executable"; then
        error "Downloaded file is not an executable" \
              "下载的文件不是可执行文件"
    fi
    
    # Check file size / 检查文件大小
    local size=$(wc -c < "$DOWNLOAD_PATH")
    if [ "$size" -lt 1000000 ]; then  # At least 1MB / 至少1MB
        error "Downloaded file size is abnormal, download might be incomplete" \
              "下载的文件大小异常，可能下载不完整"
    fi

    # Set executable permissions / 设置可执行权限
    info "Setting executable permissions..." "正在设置可执行权限..."
    if ! chmod +x "$DOWNLOAD_PATH"; then
        error "Failed to set executable permissions" "无法设置可执行权限"
    fi
}

# 在文件开头添加配置项
KEEP_BINARY=true  # 修改默认值为 true
DOWNLOAD_DIR="."   # 默认下载到当前目录

# 在 main 函数之前添加参数解析
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --keep-binary)
                KEEP_BINARY=true
                shift
                ;;
            --download-dir=*)
                DOWNLOAD_DIR="${1#*=}"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
}

# Main installation process / 主安装流程
main() {
    info "Starting installation of cursor-id-modifier ${VERSION}..." \
         "开始安装 cursor-id-modifier ${VERSION}..."
    
    # Initialize installation / 初始化安装
    detect_platform
    INSTALL_DIR="/usr/local/bin"
    if [ ! -d "$INSTALL_DIR" ]; then
        if ! mkdir -p "$INSTALL_DIR" 2>/dev/null; then
            error "Failed to create installation directory" \
                  "无法创建安装目录"
        fi
    fi
    
    # Check requirements / 检查要求
    check_requirements
    
    # Create temp directory / 创建临时目录
    info "Creating temporary directory..." \
         "正在创建临时目录..."
    TEMP_DIR=$(mktemp -d)
    info "Note: Temporary directory will be automatically cleaned up after installation" \
         "注意：临时目录将在安装完成后自动清理"
    trap 'rm -rf "$TEMP_DIR"' EXIT
    
    # 检查下载目录权限
    if [ ! -w "$DOWNLOAD_DIR" ]; then
        error "No write permission for download directory: $DOWNLOAD_DIR" \
              "下载目录无写入权限：$DOWNLOAD_DIR"
    fi
    
    # 下载二进制文件
    info "Downloading cursor-id-modifier ($OS-$ARCH)..." \
         "正在下载 cursor-id-modifier ($OS-$ARCH)..."
    
    # 定义下载 URL
    DOWNLOAD_URL="https://github.com/yuaotian/go-cursor-help/raw/refs/heads/master/bin/$BINARY_NAME"
    DOWNLOAD_PATH="$DOWNLOAD_DIR/$BINARY_NAME"
    info "File will be downloaded to: $DOWNLOAD_PATH" \
         "文件将下载到：$DOWNLOAD_PATH"
    
    if ! curl -L --progress-bar "$DOWNLOAD_URL" -o "$DOWNLOAD_PATH"; then
        error "Failed to download binary from: $DOWNLOAD_URL" \
              "从以下地址下载二进制文件失败：$DOWNLOAD_URL"
    fi
    
    success "Download completed to: $DOWNLOAD_PATH" \
            "下载完成，文件位置：$DOWNLOAD_PATH"
    
    # 添加手动设置权限的提示
    info "To make the file executable, run:" \
         "要使文件可执行，请运行："
    info "chmod +x $DOWNLOAD_PATH" \
         "chmod +x $DOWNLOAD_PATH"
    info "Then you can run it with:" \
         "然后可以通过以下命令运行："
    info "./$BINARY_NAME" \
         "./$BINARY_NAME"
    
    # 验证和安装
    verify_binary
    
    # 安装到系统目录
    info "Installing binary..." "正在安装二进制文件..."
    if ! cp "$DOWNLOAD_PATH" "$INSTALL_DIR/cursor-id-modifier"; then
        error "Failed to install binary" "安装二进制文件失败"
    fi
    
    # 根据设置决定是否保留下载的文件
    if [ "$KEEP_BINARY" = false ]; then
        info "Binary file will be cleaned up after installation" \
             "二进制文件将在安装后被清理"
        info "Use --keep-binary flag to keep the downloaded file" \
             "使用 --keep-binary 参数可以保留下载的文件"
        info "Cleaning up downloaded file..." "正在清理下载的文件..."
        rm -f "$DOWNLOAD_PATH"
    else
        info "Binary file is kept at: $DOWNLOAD_PATH" \
             "二进制文件保留在：$DOWNLOAD_PATH"
    fi
    
    success "Installation successful! You can now run 'cursor-id-modifier' from anywhere." \
            "安装成功！现在可以在任何位置运行 'cursor-id-modifier'。"
    success "For help, run 'cursor-id-modifier --help'" \
            "如需帮助，请运行 'cursor-id-modifier --help'"
}

cleanup_old_version() {
    if [ -f "$INSTALL_DIR/cursor-id-modifier" ]; then
        info "Removing old version..." "正在删除旧版..."
        rm -f "$INSTALL_DIR/cursor-id-modifier" || \
            error "Failed to remove old version" "删除旧版本失败"
    fi
}

# 在主程序开始前解析参数
parse_args "$@"

# Start installation / 开始安装
main