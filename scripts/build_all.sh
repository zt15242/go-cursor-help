#!/bin/bash

# 设置颜色代码 / Set color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color / 无颜色

# Messages / 消息
EN_MESSAGES=(
    "Starting build process for version"
    "Cleaning old builds..."
    "Creating bin directory..."
    "Failed to create bin directory"
    "Building for"
    "Successfully built:"
    "Failed to build for"
    "Build Summary:"
    "Successful builds:"
    "Failed builds:"
    "Generated files:"
    "Build process interrupted"
    "Error:"
)

CN_MESSAGES=(
    "开始构建版本"
    "正在清理旧的构建文件..."
    "正在创建bin目录..."
    "创建bin目录失败"
    "正在构建"
    "构建成功："
    "构建失败："
    "构建摘要："
    "成功构建数："
    "失败构建数："
    "生成的文件："
    "构建过程被中断"
    "错误："
)

# 版本信息 / Version info
VERSION="1.0.0"

# Detect system language / 检测系统语言
detect_language() {
    if [[ $(locale | grep "LANG=zh_CN") ]]; then
        echo "cn"
    else
        echo "en"
    fi
}

# Get message based on language / 根据语言获取消息
get_message() {
    local index=$1
    local lang=$(detect_language)
    
    if [[ "$lang" == "cn" ]]; then
        echo "${CN_MESSAGES[$index]}"
    else
        echo "${EN_MESSAGES[$index]}"
    fi
}

# 错误处理函数 / Error handling function
handle_error() {
    echo -e "${RED}$(get_message 12) $1${NC}"
    exit 1
}

# 清理函数 / Cleanup function
cleanup() {
    echo "$(get_message 1)"
    rm -rf ../bin
}

# 创建输出目录 / Create output directory
create_output_dir() {
    echo "$(get_message 2)"
    mkdir -p ../bin || handle_error "$(get_message 3)"
}

# 构建函数 / Build function
build() {
    local os=$1
    local arch=$2
    local suffix=$3
    
    echo -e "\n$(get_message 4) $os ($arch)..."
    
    output_name="../bin/cursor_id_modifier_v${VERSION}_${os}_${arch}${suffix}"
    
    GOOS=$os GOARCH=$arch go build -o "$output_name" ../main.go
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $(get_message 5) ${output_name}${NC}"
    else
        echo -e "${RED}✗ $(get_message 6) $os $arch${NC}"
        return 1
    fi
}

# 主函数 / Main function
main() {
    # 显示构建信息 / Display build info
    echo "$(get_message 0) ${VERSION}"
    
    # 清理旧文件 / Clean old files
    cleanup
    
    # 创建输出目录 / Create output directory
    create_output_dir
    
    # 定义构建目标 / Define build targets
    declare -A targets=(
        ["windows_amd64"]=".exe"
        ["darwin_amd64"]=""
        ["darwin_arm64"]=""
        ["linux_amd64"]=""
    )
    
    # 构建计数器 / Build counters
    local success_count=0
    local fail_count=0
    
    # 遍历所有目标进行构建 / Build all targets
    for target in "${!targets[@]}"; do
        os=${target%_*}
        arch=${target#*_}
        suffix=${targets[$target]}
        
        if build "$os" "$arch" "$suffix"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    # 显示构建结果 / Display build results
    echo -e "\n$(get_message 7)"
    echo -e "${GREEN}$(get_message 8) $success_count${NC}"
    if [ $fail_count -gt 0 ]; then
        echo -e "${RED}$(get_message 9) $fail_count${NC}"
    fi
    
    # 显示生成的文件列表 / Display generated files
    echo -e "\n$(get_message 10)"
    ls -1 ../bin
}

# 捕获错误信号 / Catch error signals
trap 'echo -e "\n${RED}$(get_message 11)${NC}"; exit 1' INT TERM

# 执行主函数 / Execute main function
main