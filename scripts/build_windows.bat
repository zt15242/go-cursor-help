@echo off
echo Building for Windows...
set GOOS=windows
set GOARCH=amd64
go build -o ../bin/cursor_id_modifier.exe ../main.go
echo Build complete: ../bin/cursor_id_modifier.exe 