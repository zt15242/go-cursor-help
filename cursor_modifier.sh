#!/bin/bash

# 版本号 - 与其他文件保持一致
VERSION="2.0.0"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 语言检测优化
detect_language() {
    local lang
    if [ -n "$LANG" ]; then
        lang="$LANG"
    else
        lang=$(locale | grep "LANG=" | cut -d= -f2)
    fi
    
    if [[ $lang == *"zh"* ]]; then
        echo "cn"
    else
        echo "en"
    fi
}

LANG=$(detect_language)

# 多语言文本 - 修复编码问题
if [ "$LANG" == "cn" ]; then
    SUCCESS_MSG="[√] 配置文件已成功更新！"
    RESTART_MSG="[!] 请手动重启 Cursor 以使更新生效"
    READING_CONFIG="正在读取配置文件..."
    GENERATING_IDS="正在生成新的标识符..."
    CHECKING_PROCESSES="正在检查运行中的 Cursor 实例..."
    CLOSING_PROCESSES="正在关闭 Cursor 实例..."
    PROCESSES_CLOSED="所有 Cursor 实例已关闭"
    PLEASE_WAIT="请稍候..."
    ERROR_NO_ROOT="请使用 sudo 运行此脚本"
    ERROR_CONFIG_PATH="无法获取配置文件路径"
    ERROR_CREATE_DIR="无法创建配置目录"
    ERROR_WRITE_CONFIG="无法写入配置文件"
else
    SUCCESS_MSG="[√] Configuration file updated successfully!"
    RESTART_MSG="[!] Please restart Cursor manually for changes to take effect"
    READING_CONFIG="Reading configuration file..."
    GENERATING_IDS="Generating new identifiers..."
    CHECKING_PROCESSES="Checking for running Cursor instances..."
    CLOSING_PROCESSES="Closing Cursor instances..."
    PROCESSES_CLOSED="All Cursor instances have been closed"
    PLEASE_WAIT="Please wait..."
    ERROR_NO_ROOT="Please run this script with sudo"
    ERROR_CONFIG_PATH="Unable to get config file path"
    ERROR_CREATE_DIR="Unable to create config directory"
    ERROR_WRITE_CONFIG="Unable to write config file"
fi

# 生成随机ID - 添加错误处理
generate_machine_id() {
    if ! command -v openssl >/dev/null 2>&1; then
        echo "$(head -c 32 /dev/urandom | xxd -p)"
    else
        openssl rand -hex 32
    fi
}

generate_dev_device_id() {
    local uuid=""
    if command -v uuidgen >/dev/null 2>&1; then
        uuid=$(uuidgen)
    else
        uuid=$(printf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x' \
            $RANDOM $RANDOM \
            $RANDOM \
            $(($RANDOM & 0x0fff | 0x4000)) \
            $(($RANDOM & 0x3fff | 0x8000)) \
            $RANDOM $RANDOM $RANDOM)
    fi
    echo "$uuid"
}

# 获取配置文件路径 - 优化路径处理
get_config_path() {
    local username=$1
    case "$(uname)" in
        "Darwin")
            echo "/Users/$username/Library/Application Support/Cursor/User/globalStorage/storage.json"
            ;;
        "Linux")
            echo "/home/$username/.config/Cursor/User/globalStorage/storage.json"
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
}

# 检查Cursor进程 - 添加错误处理
check_cursor_running() {
    if ! command -v pgrep >/dev/null 2>&1; then
        ps aux | grep -i "Cursor\|AppRun" | grep -v grep >/dev/null
    else
        pgrep -f "Cursor|AppRun" >/dev/null
    fi
}

# 关闭Cursor进程 - 优化进程关闭
kill_cursor_processes() {
    echo -e "${CYAN}$CLOSING_PROCESSES${NC}"
    if command -v pkill >/dev/null 2>&1; then
        pkill -f "Cursor|AppRun"
    else
        killall Cursor 2>/dev/null
        killall AppRun 2>/dev/null
    fi
    sleep 2
    if check_cursor_running; then
        if command -v pkill >/dev/null 2>&1; then
            pkill -9 -f "Cursor|AppRun"
        else
            killall -9 Cursor 2>/dev/null
            killall -9 AppRun 2>/dev/null
        fi
    fi
    echo -e "${GREEN}$PROCESSES_CLOSED${NC}"
}

# 打印banner - 修复显示问题
print_banner() {
    echo -e "${CYAN}"
    echo '    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ '
    echo '   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗'
    echo '   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝'
    echo '   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗'
    echo '   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║'
    echo '    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝'
    echo -e "${NC}"
    echo -e "${YELLOW}\t\t>> Cursor ID Modifier ${VERSION} <<${NC}"
    echo -e "${CYAN}\t\t   [ By Pancake Fruit Rolled Shark Chili ]${NC}"
    echo
}

# 主函数 - 添加错误处理
main() {
    # 检查root权限
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}${ERROR_NO_ROOT}${NC}"
        exit 1
    fi

    # 获取实际用户名
    REAL_USER=${SUDO_USER:-$USER}
    
    clear
    print_banner
    
    # 确保Cursor已关闭
    if check_cursor_running; then
        kill_cursor_processes
    fi
    
    CONFIG_PATH=$(get_config_path "$REAL_USER")
    if [ -z "$CONFIG_PATH" ]; then
        echo -e "${RED}${ERROR_CONFIG_PATH}${NC}"
        exit 1
    fi
    echo -e "${CYAN}$READING_CONFIG${NC}"
    
    # 生成新配置
    echo -e "${CYAN}$GENERATING_IDS${NC}"
    NEW_CONFIG=$(cat <<EOF
{
    "telemetry.macMachineId": "$(generate_machine_id)",
    "telemetry.machineId": "$(generate_machine_id)",
    "telemetry.devDeviceId": "$(generate_dev_device_id)",
    "telemetry.sqmId": "$(generate_machine_id)"
}
EOF
)
    
    # 创建目录(如果不存在)
    if ! mkdir -p "$(dirname "$CONFIG_PATH")" 2>/dev/null; then
        echo -e "${RED}${ERROR_CREATE_DIR}${NC}"
        exit 1
    fi
    
    # 保存配置
    if ! echo "$NEW_CONFIG" > "$CONFIG_PATH"; then
        echo -e "${RED}${ERROR_WRITE_CONFIG}${NC}"
        exit 1
    fi
    
    chown "$REAL_USER" "$CONFIG_PATH" 2>/dev/null
    chmod 644 "$CONFIG_PATH" 2>/dev/null
    
    # 显示成功消息
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}$SUCCESS_MSG${NC}"
    echo -e "${YELLOW}$RESTART_MSG${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "\n配置文件位置/Config file location:"
    echo -e "${CYAN}$CONFIG_PATH${NC}\n"
    
    read -p "Press Enter to exit..."
}

main "$@" 