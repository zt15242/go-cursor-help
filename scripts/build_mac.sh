#!/bin/bash
echo "Building for macOS..."
export GOOS=darwin
export GOARCH=amd64
go build -o ../bin/cursor_id_modifier_mac ../main.go
echo "Build complete: ../bin/cursor_id_modifier_mac"

# Build for Apple Silicon
echo "Building for macOS ARM64..."
export GOOS=darwin
export GOARCH=arm64
go build -o ../bin/cursor_id_modifier_mac_arm64 ../main.go
echo "Build complete: ../bin/cursor_id_modifier_mac_arm64" 