#!/bin/bash

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 获取当前用户
get_current_user() {
    if [ "$EUID" -eq 0 ]; then
        echo "$SUDO_USER"
    else
        echo "$USER"
    fi
}

CURRENT_USER=$(get_current_user)
if [ -z "$CURRENT_USER" ]; then
    log_error "无法获取用户名"
    exit 1
fi

# 定义配置文件路径
STORAGE_FILE="$HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"
BACKUP_DIR="$HOME/Library/Application Support/Cursor/User/globalStorage/backups"

# 定义 Cursor 应用程序文件路径
CURSOR_APP_PATH="/Applications/Cursor.app"
MAIN_JS_PATH="$CURSOR_APP_PATH/Contents/Resources/app/out/main.js"
CLI_JS_PATH="$CURSOR_APP_PATH/Contents/Resources/app/out/vs/code/node/cliProcessMain.js"

# 检查权限
check_permissions() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 sudo 运行此脚本"
        echo "示例: sudo $0"
        exit 1
    fi
}

# 检查并关闭 Cursor 进程
check_and_kill_cursor() {
    log_info "检查 Cursor 进程..."
    
    local attempt=1
    local max_attempts=5
    
    # 函数：获取进程详细信息
    get_process_details() {
        local process_name="$1"
        log_debug "正在获取 $process_name 进程详细信息："
        ps aux | grep -i "$process_name" | grep -v grep
    }
    
    while [ $attempt -le $max_attempts ]; do
        CURSOR_PIDS=$(pgrep -i "cursor" || true)
        
        if [ -z "$CURSOR_PIDS" ]; then
            log_info "未发现运行中的 Cursor 进程"
            return 0
        fi
        
        log_warn "发现 Cursor 进程正在运行"
        get_process_details "cursor"
        
        log_warn "尝试关闭 Cursor 进程..."
        
        if [ $attempt -eq $max_attempts ]; then
            log_warn "尝试强制终止进程..."
            kill -9 $CURSOR_PIDS 2>/dev/null || true
        else
            kill $CURSOR_PIDS 2>/dev/null || true
        fi
        
        sleep 1
        
        if ! pgrep -i "cursor" > /dev/null; then
            log_info "Cursor 进程已成功关闭"
            return 0
        fi
        
        log_warn "等待进程关闭，尝试 $attempt/$max_attempts..."
        ((attempt++))
    done
    
    log_error "在 $max_attempts 次尝试后仍无法关闭 Cursor 进程"
    get_process_details "cursor"
    log_error "请手动关闭进程后重试"
    exit 1
}

# 备份系统 ID
backup_system_id() {
    log_info "正在备份系统 ID..."
    local system_id_file="$BACKUP_DIR/system_id.backup_$(date +%Y%m%d_%H%M%S)"
    
    # 获取并备份 IOPlatformExpertDevice 信息
    {
        echo "# Original System ID Backup" > "$system_id_file"
        echo "## IOPlatformExpertDevice Info:" >> "$system_id_file"
        ioreg -rd1 -c IOPlatformExpertDevice >> "$system_id_file"
        
        chmod 444 "$system_id_file"
        chown "$CURRENT_USER" "$system_id_file"
        log_info "系统 ID 已备份到: $system_id_file"
    } || {
        log_error "备份系统 ID 失败"
        return 1
    }
}

# 备份配置文件
backup_config() {
    if [ ! -f "$STORAGE_FILE" ]; then
        log_warn "配置文件不存在，跳过备份"
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/storage.json.backup_$(date +%Y%m%d_%H%M%S)"
    
    if cp "$STORAGE_FILE" "$backup_file"; then
        chmod 644 "$backup_file"
        chown "$CURRENT_USER" "$backup_file"
        log_info "配置已备份到: $backup_file"
    else
        log_error "备份失败"
        exit 1
    fi
}

# 生成随机 ID
generate_random_id() {
    # 生成32字节(64个十六进制字符)的随机数
    openssl rand -hex 32
}

# 生成随机 UUID
generate_uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]'
}

# 修改现有文件
modify_or_add_config() {
    local key="$1"
    local value="$2"
    local file="$3"
    
    if [ ! -f "$file" ]; then
        log_error "文件不存在: $file"
        return 1
    fi
    
    # 确保文件可写
    chmod 644 "$file" || {
        log_error "无法修改文件权限: $file"
        return 1
    }
    
    # 创建临时文件
    local temp_file=$(mktemp)
    
    # 检查key是否存在
    if grep -q "\"$key\":" "$file"; then
        # key存在,执行替换
        sed "s/\"$key\":[[:space:]]*\"[^\"]*\"/\"$key\": \"$value\"/" "$file" > "$temp_file" || {
            log_error "修改配置失败: $key"
            rm -f "$temp_file"
            return 1
        }
    else
        # key不存在,添加新的key-value对
        sed "s/}$/,\n    \"$key\": \"$value\"\n}/" "$file" > "$temp_file" || {
            log_error "添加配置失败: $key"
            rm -f "$temp_file"
            return 1
        }
    fi
    
    # 检查临时文件是否为空
    if [ ! -s "$temp_file" ]; then
        log_error "生成的临时文件为空"
        rm -f "$temp_file"
        return 1
    fi
    
    # 使用 cat 替换原文件内容
    cat "$temp_file" > "$file" || {
        log_error "无法写入文件: $file"
        rm -f "$temp_file"
        return 1
    }
    
    rm -f "$temp_file"
    
    # 恢复文件权限
    chmod 444 "$file"
    
    return 0
}

# 生成新的配置
generate_new_config() {
  
    # 修改系统 ID
    log_info "正在修改系统 ID..."
    
    # 备份当前系统 ID
    backup_system_id
    
    # 生成新的系统 UUID
    local new_system_uuid=$(uuidgen)
    
    # 修改系统 UUID
    sudo nvram SystemUUID="$new_system_uuid"
    printf "${YELLOW}系统 UUID 已更新为: $new_system_uuid${NC}\n"
    printf "${YELLOW}请重启系统以使更改生效${NC}\n"
    
    # 将 auth0|user_ 转换为字节数组的十六进制
    local prefix_hex=$(echo -n "auth0|user_" | xxd -p)
    local random_part=$(generate_random_id)
    local machine_id="${prefix_hex}${random_part}"
    
    local mac_machine_id=$(generate_random_id)
    local device_id=$(generate_uuid | tr '[:upper:]' '[:lower:]')
    local sqm_id="{$(generate_uuid | tr '[:lower:]' '[:upper:]')}"
    
    log_info "正在修改配置文件..."
    # 检查配置文件是否存在
    if [ ! -f "$STORAGE_FILE" ]; then
        log_error "未找到配置文件: $STORAGE_FILE"
        log_warn "请先安装并运行一次 Cursor 后再使用此脚本"
        exit 1
    fi
    
    # 确保配置文件目录存在
    mkdir -p "$(dirname "$STORAGE_FILE")" || {
        log_error "无法创建配置目录"
        exit 1
    }
    
    # 如果文件不存在，创建一个基本的 JSON 结构
    if [ ! -s "$STORAGE_FILE" ]; then
        echo '{}' > "$STORAGE_FILE" || {
            log_error "无法初始化配置文件"
            exit 1
        }
    fi
    
    # 修改现有文件
    modify_or_add_config "telemetry.machineId" "$machine_id" "$STORAGE_FILE" || exit 1
    modify_or_add_config "telemetry.macMachineId" "$mac_machine_id" "$STORAGE_FILE" || exit 1
    modify_or_add_config "telemetry.devDeviceId" "$device_id" "$STORAGE_FILE" || exit 1
    modify_or_add_config "telemetry.sqmId" "$sqm_id" "$STORAGE_FILE" || exit 1
    
    # 设置文件权限和所有者
    chmod 444 "$STORAGE_FILE"  # 改为只读权限
    chown "$CURRENT_USER" "$STORAGE_FILE"
    
    # 验证权限设置
    if [ -w "$STORAGE_FILE" ]; then
        log_warn "无法设置只读权限，尝试使用其他方法..."
        chattr +i "$STORAGE_FILE" 2>/dev/null || true
    else
        log_info "成功设置文件只读权限"
    fi
    
    echo
    log_info "已更新配置: $STORAGE_FILE"
    log_debug "machineId: $machine_id"
    log_debug "macMachineId: $mac_machine_id"
    log_debug "devDeviceId: $device_id"
    log_debug "sqmId: $sqm_id"
}

# 修改 Cursor 主程序文件
modify_cursor_app_files() {
    log_info "正在修改 Cursor 主程序文件..."
    
    # 检查 SIP 状态
    if csrutil status | grep -q "enabled"; then
        echo
        log_warn "检测到系统完整性保护(SIP)处于启用状态"
        echo
        echo -e "${YELLOW}什么是系统完整性保护(SIP)？${NC}"
        echo "SIP 是 macOS 的一项重要安全功能，它可以："
        echo "1. 防止系统关键文件被修改"
        echo "2. 保护系统进程不被注入代码"
        echo "3. 限制具有 root 权限的操作"
        echo "4. 保护系统免受恶意软件攻击"
        echo
        echo -e "${RED}关闭 SIP 的潜在风险：${NC}"
        echo "1. 系统更容易受到恶意软件攻击"
        echo "2. 可能导致系统不稳定"
        echo "3. 降低系统整体安全性"
        echo "4. 可能影响系统更新"
        echo
        echo -e "${YELLOW}如果您决定继续，需要：${NC}"
        echo "1. 重启 Mac 并进入恢复模式（启动时按住 Command + R）"
        echo "2. 打开终端，输入命令：csrutil disable"
        echo "3. 重启后再运行此脚本"
        echo "4. 完成修改后强烈建议重新启用 SIP（csrutil enable）"
        echo
        echo -e "${GREEN}安全建议：${NC}"
        echo "1. 仅在必要时临时关闭 SIP"
        echo "2. 完成修改后立即重新启用"
        echo "3. 在关闭 SIP 期间不要浏览不信任的网站或运行不明来源的软件"
        echo "4. 确保从可信来源下载和运行脚本"
        echo
        read -p "了解风险后，是否继续尝试修改文件？(y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "已取消文件修改，建议保持 SIP 开启以确保系统安全"
            return 0
        fi
        echo -e "${YELLOW}请记住在完成修改后重新启用 SIP 以确保系统安全${NC}"
    fi

    local files=("$MAIN_JS_PATH" "$CLI_JS_PATH")
    
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            log_warn "文件不存在: $file"
            continue
        fi
        
        # 创建备份
        local backup_file="${file}.bak"
        if [ ! -f "$backup_file" ]; then
            log_info "正在备份 $file"
            if ! sudo cp "$file" "$backup_file" 2>/dev/null; then
                log_error "无法备份文件: $file"
                echo -e "${YELLOW}可能原因：${NC}"
                echo "1. 系统完整性保护(SIP)已启用"
                echo "2. 文件系统权限限制"
                echo
                echo -e "${YELLOW}建议操作：${NC}"
                echo "1. 禁用 SIP 后重试"
                echo "2. 手动复制文件进行备份"
                continue
            fi
            sudo chmod 644 "$backup_file"
            sudo chown "$CURRENT_USER" "$backup_file"
        else
            log_debug "备份已存在: $backup_file"
        fi
        
        # 创建临时文件
        local temp_file=$(mktemp)
        
        # 读取文件内容
        local content=$(<"$file")
        
        # 查找关键位置
        local uuid_pattern="IOPlatformUUID"
        if ! echo "$content" | grep -q "$uuid_pattern"; then
            log_warn "在文件 $file 中未找到 $uuid_pattern"
            rm -f "$temp_file"
            continue
        fi
        
        # 构建替换内容
        local replacement='case "IOPlatformUUID": return crypto.randomUUID();'
        
        # 使用 sed 进行替换
        if ! sed -E "s/(case \"IOPlatformUUID\":)[^}]+}/\1 return crypto.randomUUID();/" "$file" > "$temp_file"; then
            log_error "处理文件内容失败: $file"
            rm -f "$temp_file"
            continue
        fi
        
        # 验证临时文件
        if [ ! -s "$temp_file" ]; then
            log_error "生成的文件为空: $file"
            rm -f "$temp_file"
            continue
        fi
        
        # 验证文件内容是否包含必要的代码
        log_debug "正在验证文件内容..."
        if ! grep -q "crypto\s*\.\s*randomUUID\s*(" "$temp_file"; then
            log_debug "文件内容预览："
            head -n 20 "$temp_file" | log_debug
            log_error "修改后的文件缺少必要的代码: $file"
            rm -f "$temp_file"
            continue
        fi
        
        #log_debug "文件验证通过"
        
        # 替换原文件
        if ! mv "$temp_file" "$file"; then
            log_error "无法更新文件: $file"
            rm -f "$temp_file"
            continue
        fi
        
        # 设置权限
        chmod 644 "$file"
        chown "$CURRENT_USER" "$file"
        
        log_info "成功修改文件: $file"
    done
    
    log_info "如果文件修改失败，请检查系统完整性保护(SIP)状态"
    log_info "您可以在终端中运行 'csrutil status' 查看当前状态"
    
    if csrutil status | grep -q "disabled"; then
        echo
        log_warn "检测到 SIP 当前已禁用"
        echo -e "${YELLOW}安全提醒：${NC}"
        echo "1. 请使用以下步骤重新启用 SIP："
        echo "   - 重启 Mac 并进入恢复模式（Command + R）"
        echo "   - 打开终端，输入：csrutil enable"
        echo "   - 重启电脑"
        echo "2. 保持 SIP 启用对系统安全性至关重要"
        echo
    fi
}

# 显示文件树结构
show_file_tree() {
    local base_dir=$(dirname "$STORAGE_FILE")
    echo
    log_info "文件结构:"
    echo -e "${BLUE}$base_dir${NC}"
    echo "├── globalStorage"
    echo "│   ├── storage.json (已修改)"
    echo "│   └── backups"
    
    # 列出备份文件
    if [ -d "$BACKUP_DIR" ]; then
        local backup_files=("$BACKUP_DIR"/*)
        if [ ${#backup_files[@]} -gt 0 ]; then
            for file in "${backup_files[@]}"; do
                if [ -f "$file" ]; then
                    echo "│       └── $(basename "$file")"
                fi
            done
        else
            echo "│       └── (空)"
        fi
    fi
    echo
}

# 显示公众号信息
show_follow_info() {
    echo
    echo -e "${GREEN}================================${NC}"
    echo -e "${YELLOW}  关注公众号【煎饼果子卷AI】一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬) ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
}

# 禁用自动更新
disable_auto_update() {
    local updater_path="$HOME/Library/Application Support/Caches/cursor-updater"
    
    echo
    log_info "正在禁用 Cursor 自动更新..."
    echo -e "${YELLOW}如果需要恢复自动更新，可以手动删除文件：${NC}"
    echo -e "${BLUE}$updater_path${NC}"
    echo
    
    # 尝试自动执行
    if sudo rm -rf "$updater_path" && \
       sudo touch "$updater_path" && \
       sudo chmod 444 "$updater_path"; then
        log_info "成功禁用自动更新"
        echo
        log_info "验证方法："
        echo "运行命令：ls -l \"$updater_path\""
        echo "确认文件权限显示为：r--r--r--"
    else
        log_error "自动设置失败，请手动执行以下命令："
        echo
        echo -e "${BLUE}sudo rm -rf \"$updater_path\" && sudo touch \"$updater_path\" && sudo chmod 444 \"$updater_path\"${NC}"
    fi
    
    echo
    log_info "完成后请重启 Cursor"
}

# 生成随机MAC地址
generate_random_mac() {
    # 生成随机MAC地址,保持第一个字节的第二位为0(保证是单播地址)
    printf '02:%02x:%02x:%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

# 获取网络接口列表
get_network_interfaces() {
    networksetup -listallhardwareports | awk '/Hardware Port|Ethernet Address/ {print $NF}' | paste - - | grep -v 'N/A'
}

# 备份MAC地址
backup_mac_addresses() {
    log_info "正在备份MAC地址..."
    local backup_file="$BACKUP_DIR/mac_addresses.backup_$(date +%Y%m%d_%H%M%S)"
    
    {
        echo "# Original MAC Addresses Backup - $(date)" > "$backup_file"
        echo "## Network Interfaces:" >> "$backup_file"
        networksetup -listallhardwareports >> "$backup_file"
        
        chmod 444 "$backup_file"
        chown "$CURRENT_USER" "$backup_file"
        log_info "MAC地址已备份到: $backup_file"
    } || {
        log_error "备份MAC地址失败"
        return 1
    }
}

# 修改MAC地址
modify_mac_address() {
    log_info "正在获取网络接口信息..."
    
    # 备份当前MAC地址
    backup_mac_addresses
    
    # 获取所有网络接口
    local interfaces=$(get_network_interfaces)
    
    if [ -z "$interfaces" ]; then
        log_error "未找到可用的网络接口"
        return 1
    fi
    
    echo
    log_info "发现以下网络接口:"
    echo "$interfaces" | nl -w2 -s') '
    echo
    
    echo -n "请选择要修改的接口编号 (按回车跳过): "
    read -r choice
    
    if [ -z "$choice" ]; then
        log_info "跳过MAC地址修改"
        return 0
    fi
    
    # 获取选择的接口名称
    local selected_interface=$(echo "$interfaces" | sed -n "${choice}p" | awk '{print $1}')
    
    if [ -z "$selected_interface" ]; then
        log_error "无效的选择"
        return 1
    fi
    
    # 生成新的MAC地址
    local new_mac=$(generate_random_mac)
    
    log_info "正在修改接口 $selected_interface 的MAC地址..."
    
    # 关闭网络接口
    sudo ifconfig "$selected_interface" down || {
        log_error "无法关闭网络接口"
        return 1
    }
    
    # 修改MAC地址
    if sudo ifconfig "$selected_interface" ether "$new_mac"; then
        # 重新启用网络接口
        sudo ifconfig "$selected_interface" up
        log_info "成功修改MAC地址为: $new_mac"
        echo
        log_warn "请注意: MAC地址修改可能需要重新连接网络才能生效"
    else
        log_error "修改MAC地址失败"
        # 尝试恢复网络接口
        sudo ifconfig "$selected_interface" up
        return 1
    fi
}

# 新增恢复功能选项
restore_feature() {
    # 检查备份目录是否存在
    if [ ! -d "$BACKUP_DIR" ]; then
        log_warn "备份目录不存在"
        return 1
    fi

    # 使用 find 命令获取备份文件列表并存储到数组
    backup_files=()
    while IFS= read -r file; do
        [ -f "$file" ] && backup_files+=("$file")
    done < <(find "$BACKUP_DIR" -name "*.backup_*" -type f 2>/dev/null | sort)
    
    # 检查是否找到备份文件
    if [ ${#backup_files[@]} -eq 0 ]; then
        log_warn "未找到任何备份文件"
        return 1
    fi
    
    echo
    log_info "可用的备份文件："
    echo "0) 退出 (默认)"
    
    # 显示备份文件列表
    for i in "${!backup_files[@]}"; do
        echo "$((i+1))) $(basename "${backup_files[$i]}")"
    done
    
    echo
    echo -n "请选择要恢复的备份文件编号 [0-${#backup_files[@]}] (默认: 0): "
    read -r choice
    
    # 处理用户输入
    if [ -z "$choice" ] || [ "$choice" = "0" ]; then
        log_info "跳过恢复操作"
        return 0
    fi
    
    # 验证输入
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -gt "${#backup_files[@]}" ]; then
        log_error "无效的选择"
        return 1
    fi
    
    # 获取选择的备份文件
    local selected_backup="${backup_files[$((choice-1))]}"
    
    # 验证文件存在性和可读性
    if [ ! -f "$selected_backup" ] || [ ! -r "$selected_backup" ]; then
        log_error "无法访问选择的备份文件"
        return 1
    fi
    
    # 尝试恢复配置
    if cp "$selected_backup" "$STORAGE_FILE"; then
        chmod 644 "$STORAGE_FILE"
        chown "$CURRENT_USER" "$STORAGE_FILE"
        log_info "已从备份文件恢复配置: $(basename "$selected_backup")"
        return 0
    else
        log_error "恢复配置失败"
        return 1
    fi
}

# 主函数
main() {
    
    # 新增环境检查
    if [[ $(uname) != "Darwin" ]]; then
        log_error "本脚本仅支持 macOS 系统"
        exit 1
    fi
    
    
    clear
    # 显示 Logo
    echo -e "
    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
    "
    echo -e "${BLUE}================================${NC}"
    echo -e "${GREEN}   Cursor 设备ID 修改工具          ${NC}"
    echo -e "${YELLOW}  关注公众号【煎饼果子卷AI】     ${NC}"
    echo -e "${YELLOW}  一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬)  ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    echo -e "${YELLOW}[重要提示]${NC} 本工具支持 Cursor v0.45.x"
    echo -e "${YELLOW}[重要提示]${NC} 本工具免费，如果对您有帮助，请关注公众号【煎饼果子卷AI】"
    echo
    
    check_permissions
    check_and_kill_cursor
    backup_config
    generate_new_config
    modify_cursor_app_files
    
    # 添加MAC地址修改选项
    echo
    log_warn "是否要修改MAC地址？"
    echo "0) 否 - 保持默认设置 (按回车键)"
    echo "1) 是 - 修改MAC地址"
    read -r choice
    
    if [ "$choice" = "1" ]; then
        modify_mac_address
    fi
    
    echo
    log_info "MAC地址修改完成！"
    show_file_tree
    show_follow_info
  
    # 直接执行禁用自动更新
    disable_auto_update

    log_info "请重启 Cursor 以应用新的配置"

    # 新增恢复功能选项
    restore_feature

    # 显示最后的提示信息
    show_follow_info

    
}

# 执行主函数
main

