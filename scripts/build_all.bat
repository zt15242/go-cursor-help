@echo off
echo Creating bin directory...
if not exist "..\bin" mkdir "..\bin"

echo Building for all platforms...

echo Building for Windows AMD64...
set GOOS=windows
set GOARCH=amd64
go build -o ../bin/cursor_id_modifier.exe ../main.go

echo Building for macOS AMD64...
set GOOS=darwin
set GOARCH=amd64
go build -o ../bin/cursor_id_modifier_mac ../main.go

echo Building for macOS ARM64...
set GOOS=darwin
set GOARCH=arm64
go build -o ../bin/cursor_id_modifier_mac_arm64 ../main.go

echo Building for Linux AMD64...
set GOOS=linux
set GOARCH=amd64
go build -o ../bin/cursor_id_modifier_linux ../main.go

echo All builds completed!
pause 