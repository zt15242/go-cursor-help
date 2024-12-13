#!/bin/bash

# 设置颜色代码
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 版本信息
VERSION="2.0.0"

# 错误处理函数
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# 清理函数
cleanup() {
    echo "Cleaning old builds..."
    rm -rf ../bin
}

# 创建输出目录
create_output_dir() {
    echo "Creating bin directory..."
    mkdir -p ../bin || handle_error "Failed to create bin directory"
}

# 构建函数
build() {
    local os=$1
    local arch=$2
    local suffix=$3
    
    echo -e "\nBuilding for $os ($arch)..."
    
    output_name="../bin/cursor_id_modifier_v${VERSION}_${os}_${arch}${suffix}"
    
    GOOS=$os GOARCH=$arch go build -o "$output_name" ../main.go
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully built: ${output_name}${NC}"
    else
        echo -e "${RED}✗ Failed to build for $os $arch${NC}"
        return 1
    fi
}

# 主函数
main() {
    # 显示构建信息
    echo "Starting build process for version ${VERSION}"
    
    # 清理旧文件
    cleanup
    
    # 创建输出目录
    create_output_dir
    
    # 定义构建目标
    declare -A targets=(
        ["windows_amd64"]=".exe"
        ["darwin_amd64"]=""
        ["darwin_arm64"]=""
        ["linux_amd64"]=""
    )
    
    # 构建计数器
    local success_count=0
    local fail_count=0
    
    # 遍历所有目标进行构建
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
    
    # 显示构建结果
    echo -e "\nBuild Summary:"
    echo -e "${GREEN}Successful builds: $success_count${NC}"
    if [ $fail_count -gt 0 ]; then
        echo -e "${RED}Failed builds: $fail_count${NC}"
    fi
    
    # 显示生成的文件列表
    echo -e "\nGenerated files:"
    ls -1 ../bin
}

# 捕获错误信号
trap 'echo -e "\n${RED}Build process interrupted${NC}"; exit 1' INT TERM

# 执行主函数
main 