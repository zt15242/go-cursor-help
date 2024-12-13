#!/bin/bash

# 版本号
VERSION="1.0.1"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 语言检测
detect_language() {
    local lang=$(locale | grep "LANG=" | cut -d= -f2)
    if [[ $lang == *"zh"* ]]; then
        echo "cn"
    else
        echo "en"
    fi
}

LANG=$(detect_language)

# 多语言文本
if [ "$LANG" == "cn" ]; then
    SUCCESS_MSG="[√] 配置文件已成功更新！"
    RESTART_MSG="[!] 请手动重启 Cursor 以使更新生效"
    READING_CONFIG="正在读取配置文件..."
    GENERATING_IDS="正在生成新的标识符..."
    CHECKING_PROCESSES="正在检查运行中的 Cursor 实例..."
    CLOSING_PROCESSES="正在关闭 Cursor 实例..."
    PROCESSES_CLOSED="所有 Cursor 实例已关闭"
    PLEASE_WAIT="请稍候..."
else
    SUCCESS_MSG="[√] Configuration file updated successfully!"
    RESTART_MSG="[!] Please restart Cursor manually for changes to take effect"
    READING_CONFIG="Reading configuration file..."
    GENERATING_IDS="Generating new identifiers..."
    CHECKING_PROCESSES="Checking for running Cursor instances..."
    CLOSING_PROCESSES="Closing Cursor instances..."
    PROCESSES_CLOSED="All Cursor instances have been closed"
    PLEASE_WAIT="Please wait..."
fi

# 生成随机ID
generate_machine_id() {
    openssl rand -hex 32
}

generate_dev_device_id() {
    printf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x' \
        $RANDOM $RANDOM \
        $RANDOM \
        $(($RANDOM & 0x0fff | 0x4000)) \
        $(($RANDOM & 0x3fff | 0x8000)) \
        $RANDOM $RANDOM $RANDOM
}

# 获取配置文件路径
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
            echo "Unsupported operating system"
            exit 1
            ;;
    esac
}

# 检查Cursor进程
check_cursor_running() {
    pgrep -f "Cursor|AppRun" >/dev/null
}

# 关闭Cursor进程
kill_cursor_processes() {
    echo -e "${CYAN}$CLOSING_PROCESSES${NC}"
    pkill -f "Cursor|AppRun"
    sleep 2
    if check_cursor_running; then
        pkill -9 -f "Cursor|AppRun"
    fi
    echo -e "${GREEN}$PROCESSES_CLOSED${NC}"
}

# 打印赛博朋克风格banner
print_banner() {
    echo -e "${CYAN}"
    echo '    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ '
    echo '   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗'
    echo '   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝'
    echo '   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗'
    echo '   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║'
    echo '    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝'
    echo -e "${NC}"
    echo -e "${YELLOW}\t\t>> Cursor ID Modifier v1.0 <<${NC}"
    echo -e "${CYAN}\t\t   [ By Pancake Fruit Rolled Shark Chili ]${NC}"
    echo
}

# 主函数
main() {
    # 检查root权限
    if [ "$EUID" -ne 0 ]; then 
        echo "Please run as root"
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
    echo -e "${CYAN}$READING_CONFIG${NC}"
    
    # 生成新配置
    echo -e "${CYAN}$GENERATING_IDS${NC}"
    NEW_CONFIG=$(cat <<EOF
{
    "telemetry.macMachineId": "$(generate_machine_id)",
    "telemetry.machineId": "$(generate_machine_id)",
    "telemetry.devDeviceId": "$(generate_dev_device_id)",
    "telemetry.sqmId": "$(generate_machine_id)",
    "lastModified": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "version": "$VERSION"
}
EOF
)
    
    # 创建目录(如果不存在)
    mkdir -p "$(dirname "$CONFIG_PATH")"
    
    # 保存配置
    echo "$NEW_CONFIG" > "$CONFIG_PATH"
    chown "$REAL_USER" "$CONFIG_PATH"
    chmod 644 "$CONFIG_PATH"
    
    # 显示成功消息
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}$SUCCESS_MSG${NC}"
    echo -e "${YELLOW}$RESTART_MSG${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "\n���置文件位置/Config file location:"
    echo -e "${CYAN}$CONFIG_PATH${NC}\n"
    
    read -p "Press Enter to exit..."
}

main "$@" 