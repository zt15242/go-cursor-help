@echo off
setlocal EnableDelayedExpansion

:: 设置版本信息
set VERSION=1.0.0

:: 设置颜色代码
set "GREEN=[32m"
set "RED=[31m"
set "YELLOW=[33m"
set "RESET=[0m"

:: 设置编译优化标志
set "LDFLAGS=-s -w"
set "BUILDMODE=pie"
set "GCFLAGS=-N -l"

:: 检查是否安装了必要的交叉编译工具
where gcc >nul 2>nul
if %errorlevel% neq 0 (
    echo %RED%错误: 未找到 gcc，这可能会影响 Mac 系统的交叉编译%RESET%
    echo %YELLOW%请安装 MinGW-w64 或其他 gcc 工具链%RESET%
    pause
    exit /b 1
)

:: 设置 CGO
set CGO_ENABLED=0

:: 显示编译信息
echo %YELLOW%开始构建 version %VERSION%%RESET%
echo %YELLOW%使用优化标志: LDFLAGS=%LDFLAGS%, BUILDMODE=%BUILDMODE%%RESET%
echo %YELLOW%CGO_ENABLED=%CGO_ENABLED%%RESET%

:: 仅在必要时清理旧文件
if "%1"=="clean" (
    echo 清理旧构建文件...
    if exist "..\bin" rd /s /q "..\bin"
)

:: 创建输出目录
if not exist "..\bin" mkdir "..\bin" 2>nul

:: 定义目标平台数组
set platforms[0].os=windows
set platforms[0].arch=amd64
set platforms[0].ext=.exe

set platforms[1].os=darwin
set platforms[1].arch=amd64
set platforms[1].ext=

set platforms[2].os=darwin
set platforms[2].arch=arm64
set platforms[2].ext=

set platforms[3].os=linux
set platforms[3].arch=amd64
set platforms[3].ext=

:: 设置开始时间
set start_time=%time%

:: 编译所有目标
echo 开始编译所有平台...

for /L %%i in (0,1,3) do (
    set "os=!platforms[%%i].os!"
    set "arch=!platforms[%%i].arch!"
    set "ext=!platforms[%%i].ext!"
    
    echo.
    echo Building for !os! !arch!...
    
    set GOOS=!os!
    set GOARCH=!arch!
    
    :: 为 darwin 系统设置特殊编译参数和文件名
    if "!os!"=="darwin" (
        set "extra_flags=-tags ios"
        if "!arch!"=="amd64" (
            set "outfile=..\bin\cursor_id_modifier_v%VERSION%_mac_intel!ext!"
        ) else (
            set "outfile=..\bin\cursor_id_modifier_v%VERSION%_mac_m1!ext!"
        )
    ) else (
        set "extra_flags="
        set "outfile=..\bin\cursor_id_modifier_v%VERSION%_!os!_!arch!!ext!"
    )
    
    go build -trimpath !extra_flags! -buildmode=%BUILDMODE% -ldflags="%LDFLAGS%" -gcflags="%GCFLAGS%" -o "!outfile!" ..\main.go
    
    if !errorlevel! equ 0 (
        echo %GREEN%Build successful: !outfile!%RESET%
    ) else (
        echo %RED%Build failed for !os! !arch!%RESET%
        echo %YELLOW%如果是 Mac 系统编译失败，请确保：%RESET%
        echo %YELLOW%1. 已安装 MinGW-w64%RESET%
        echo %YELLOW%2. 已设置 GOARCH 和 GOOS%RESET%
        echo %YELLOW%3. CGO_ENABLED=0%RESET%
    )
)

:: 计算总耗时
set end_time=%time%
set options="tokens=1-4 delims=:.,"
for /f %options% %%a in ("%start_time%") do set start_s=%%a&set start_m=%%b&set start_h=%%c
for /f %options% %%a in ("%end_time%") do set end_s=%%a&set end_m=%%b&set end_h=%%c
set /a duration = (end_h - start_h) * 3600 + (end_m - start_m) * 60 + (end_s - start_s)

echo.
echo %GREEN%所有构建完成! 总耗时: %duration% 秒%RESET%
if exist "..\bin" dir /b "..\bin"

pause
endlocal