#!/bin/bash
echo "Building for Linux..."
export GOOS=linux
export GOARCH=amd64
go build -o ../bin/cursor_id_modifier_linux ../main.go
echo "Build complete: ../bin/cursor_id_modifier_linux" 