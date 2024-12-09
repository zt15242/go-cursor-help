#!/bin/bash

# 创建bin目录（如果不存在）
mkdir -p ../bin

# Windows
echo "Building for Windows..."
GOOS=windows GOARCH=amd64 go build -o ../bin/cursor_id_modifier.exe ../main.go

# macOS (Intel)
echo "Building for macOS (Intel)..."
GOOS=darwin GOARCH=amd64 go build -o ../bin/cursor_id_modifier_mac ../main.go

# macOS (Apple Silicon)
echo "Building for macOS (ARM64)..."
GOOS=darwin GOARCH=arm64 go build -o ../bin/cursor_id_modifier_mac_arm64 ../main.go

# Linux
echo "Building for Linux..."
GOOS=linux GOARCH=amd64 go build -o ../bin/cursor_id_modifier_linux ../main.go

echo "All builds completed!" 