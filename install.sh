#!/bin/bash

# Version / 版本号
VERSION="v2.5.0"

# Configuration / 配置
KEEP_BINARY=false
DOWNLOAD_DIR="/tmp"
INSTALL_DIR="/usr/local/bin"
AUTO_SUDO=false

# Colors / 颜色
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[36m'
BOLD='\033[1m'
NC='\033[0m'

# Separator / 分隔线
SEPARATOR="${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Bilingual message functions / 双语消息函数
error() {
    echo -e "\n${SEPARATOR}"
    echo -e "${RED}${BOLD}❌ Error:${NC} $1"
    echo -e "${RED}${BOLD}❌ 错误：${NC}$2"
    echo -e "${SEPARATOR}\n"
    exit 1
}

info() {
    echo -e "\n${BLUE}${BOLD}ℹ️  [EN]:${NC} $1"
    echo -e "${BLUE}${BOLD}ℹ️  [中文]:${NC} $2\n"
}

success() {
    echo -e "\n${SEPARATOR}"
    echo -e "${GREEN}${BOLD}✅ [EN]:${NC} $1"
    echo -e "${GREEN}${BOLD}✅ [中文]:${NC} $2"
    echo -e "${SEPARATOR}\n"
}

warning() {
    echo -e "\n${YELLOW}${BOLD}⚠️  [EN]:${NC} $1"
    echo -e "${YELLOW}${BOLD}⚠️  [中文]:${NC} $2\n"
}

# System detection / 系统检测
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

# System checks / 系统检查
check_requirements() {
    info "Checking system requirements..." "正在检查系统要求..."
    
    # Check network connectivity / 检查网络连接
    if ! ping -c 1 github.com >/dev/null 2>&1; then
        error "No network connection to GitHub" "无法连接到 GitHub"
    fi
    
    # Check curl / 检查curl
    if ! command -v curl >/dev/null 2>&1; then
        error "curl is required. Please install curl first." \
              "需要安装 curl。请先安装 curl 后再运行此脚本。"
    fi
}

# Privilege check / 权限检查
check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        if [ "$AUTO_SUDO" = "true" ]; then
            if command -v sudo >/dev/null 2>&1; then
                info "Re-running with sudo..." "使用 sudo 重新运行..."
                exec sudo bash "$0" "$@"
            else
                error "This script must be run as root. Please use sudo." \
                      "此脚本必须以 root 身份运行。请使用 sudo。"
            fi
        else
            error "This script must be run as root. Please use sudo." \
                  "此脚本必须以 root 身份运行。请使用 sudo。"
        fi
    fi
}

# Binary verification / 二进制验证
verify_binary() {
    info "Verifying binary..." "正在验证二进制文件..."
    
    # Check file existence / 检查文件是否存在
    if [ ! -f "$DOWNLOAD_PATH" ]; then
        error "Binary file download failed or does not exist" \
              "二进制文件下载失败或不存在"
    fi
    
    # Check executable format / 检查可执行格式
    if ! file "$DOWNLOAD_PATH" | grep -q "executable"; then
        error "Downloaded file is not an executable" \
              "下载的文件不是可执行文件"
    fi
    
    # Check file size / 检查文件大小
    local size=$(wc -c < "$DOWNLOAD_PATH")
    if [ "$size" -lt 1000000 ]; then  # At least 1MB / 至少1MB
        error "Downloaded file size is abnormal" \
              "下载的文件大小异常"
    fi

    # Set executable permissions / 设置可执行权限
    info "Setting executable permissions..." "正在设置可执行权限..."
    if ! chmod +x "$DOWNLOAD_PATH"; then
        error "Failed to set executable permissions" "无法设置可执行权限"
    fi
}

# Cleanup functions / 清理函数
cleanup_old_version() {
    if [ -f "$INSTALL_DIR/cursor-id-modifier" ]; then
        info "Removing old version..." "正在删除旧版..."
        rm -f "$INSTALL_DIR/cursor-id-modifier" || \
            error "Failed to remove old version" "删除旧版本失败"
    fi
}

cleanup_temp_files() {
    if [ "$KEEP_BINARY" = "false" ]; then
        rm -f "$DOWNLOAD_PATH"
        rm -f "$INSTALL_DIR/cursor-id-modifier-wrapper"
    fi
}

# Parse arguments / 解析参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-sudo)
                AUTO_SUDO=true
                shift
                ;;
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

# Print banner / 打印横幅
print_banner() {
    echo -e "\n${BLUE}${BOLD}"
    echo "    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗"
    echo "   ██╔════╝██║   ██║██╔══██╗██╔════╝█╔═══██╗██╔══██╗"
    echo "   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝"
    echo "   ██║     ██║   ██║██╔══██╗╚════██ ██║   ██║██╔══██╗"
    echo "   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║"
    echo "    ╚════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚════╝ ╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "${YELLOW}${BOLD}         >> Cursor ID Modifier ${VERSION} <<${NC}"
    echo -e "${BLUE}${BOLD}      [ By Pancake Fruit Rolled Shark Chili ]${NC}\n"
}

# Main installation process / 主安装流程
main() {
    check_privileges "$@"
    
    print_banner
    
    info "Starting installation of cursor-id-modifier ${VERSION}..." \
         "开始安装 cursor-id-modifier ${VERSION}..."
    
    detect_platform
    check_requirements
    
    # Create installation directory / 创建安装目录
    mkdir -p "$INSTALL_DIR" 2>/dev/null || \
        error "Failed to create installation directory" "无法创建安装目录"
    
    # Download binary / 下载二进制文件
    info "Downloading cursor-id-modifier ($OS-$ARCH)..." \
         "正在下载 cursor-id-modifier ($OS-$ARCH)..."
    
    DOWNLOAD_URL="https://github.com/yuaotian/go-cursor-help/raw/refs/heads/master/bin/$BINARY_NAME"
    DOWNLOAD_PATH="$DOWNLOAD_DIR/$BINARY_NAME"
    
    if ! curl -L --progress-bar "$DOWNLOAD_URL" -o "$DOWNLOAD_PATH"; then
        error "Failed to download binary" "下载二进制文件失败"
    fi
    
    success "Download completed" "下载完成"
    
    verify_binary
    cleanup_old_version
    
    # Install binary / 安装二进制文件
    info "Installing binary..." "正在安装二进制文件..."
    if ! cp "$DOWNLOAD_PATH" "$INSTALL_DIR/cursor-id-modifier"; then
        error "Failed to install binary" "安装二进制文件失败"
    fi
    
    # Create wrapper script / 创建包装脚本
    cat > "$INSTALL_DIR/cursor-id-modifier-wrapper" << 'EOF'
#!/bin/bash
if [ "$(uname -s)" = "Darwin" ]; then
    sudo /usr/local/bin/cursor-id-modifier "$@"
else
    sudo /usr/local/bin/cursor-id-modifier "$@"
fi
EOF
    chmod +x "$INSTALL_DIR/cursor-id-modifier-wrapper"
    
    # Cleanup / 清理
    cleanup_temp_files
    
    success "Installation successful! Run 'cursor-id-modifier-wrapper' from anywhere." \
            "安装成功！现在可以在任何位置运行 'cursor-id-modifier-wrapper'。"
}

# Start installation / 开始安装
parse_args "$@"
main "$@"