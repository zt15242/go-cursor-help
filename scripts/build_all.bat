@echo off
setlocal EnableDelayedExpansion

:: Messages / 消息
set "EN_MESSAGES[0]=Starting build process for version"
set "EN_MESSAGES[1]=Using optimization flags:"
set "EN_MESSAGES[2]=Cleaning old builds..."
set "EN_MESSAGES[3]=Cleanup completed"
set "EN_MESSAGES[4]=bin directory does not exist, no cleanup needed"
set "EN_MESSAGES[5]=Starting builds for all platforms..."
set "EN_MESSAGES[6]=Building for"
set "EN_MESSAGES[7]=Build successful:"
set "EN_MESSAGES[8]=Build failed for"
set "EN_MESSAGES[9]=All builds completed! Total time:"
set "EN_MESSAGES[10]=seconds"

set "CN_MESSAGES[0]=开始构建版本"
set "CN_MESSAGES[1]=使用优化标志："
set "CN_MESSAGES[2]=正在清理旧的构建文件..."
set "CN_MESSAGES[3]=清理完成"
set "CN_MESSAGES[4]=bin 目录不存在，无需清理"
set "CN_MESSAGES[5]=开始编译所有平台..."
set "CN_MESSAGES[6]=正在构建"
set "CN_MESSAGES[7]=构建成功："
set "CN_MESSAGES[8]=构建失败："
set "CN_MESSAGES[9]=所有构建完成！总耗时："
set "CN_MESSAGES[10]=秒"

:: 设置版本信息 / Set version
set VERSION=2.0.0

:: 设置颜色代码 / Set color codes
set "GREEN=[32m"
set "RED=[31m"
set "YELLOW=[33m"
set "RESET=[0m"

:: 设置编译优化标志 / Set build optimization flags
set "LDFLAGS=-s -w"
set "BUILDMODE=pie"
set "GCFLAGS=-N -l"

:: 设置 CGO / Set CGO
set CGO_ENABLED=0

:: 检测系统语言 / Detect system language
for /f "tokens=2 delims==" %%a in ('wmic os get OSLanguage /value') do set OSLanguage=%%a
if "%OSLanguage%"=="2052" (set LANG=cn) else (set LANG=en)

:: 显示编译信息 / Display build info
echo %YELLOW%!%LANG%_MESSAGES[0]! %VERSION%%RESET%
echo %YELLOW%!%LANG%_MESSAGES[1]! LDFLAGS=%LDFLAGS%, BUILDMODE=%BUILDMODE%%RESET%
echo %YELLOW%CGO_ENABLED=%CGO_ENABLED%%RESET%

:: 清理旧的构建文件 / Clean old builds
echo %YELLOW%!%LANG%_MESSAGES[2]!%RESET%
if exist "..\bin" (
    rd /s /q "..\bin"
    echo %GREEN%!%LANG%_MESSAGES[3]!%RESET%
) else (
    echo %YELLOW%!%LANG%_MESSAGES[4]!%RESET%
)

:: 创建输出目录 / Create output directory
mkdir "..\bin" 2>nul

:: 定义目标平台数组 / Define target platforms array
set platforms[0].os=windows
set platforms[0].arch=amd64
set platforms[0].ext=.exe
set platforms[0].suffix=

set platforms[1].os=darwin
set platforms[1].arch=amd64
set platforms[1].ext=
set platforms[1].suffix=_intel

set platforms[2].os=darwin
set platforms[2].arch=arm64
set platforms[2].ext=
set platforms[2].suffix=_m1

set platforms[3].os=linux
set platforms[3].arch=amd64
set platforms[3].ext=
set platforms[3].suffix=

:: 设置开始时间 / Set start time
set start_time=%time%

:: 编译所有目标 / Build all targets
echo !%LANG%_MESSAGES[5]!

for /L %%i in (0,1,3) do (
    set "os=!platforms[%%i].os!"
    set "arch=!platforms[%%i].arch!"
    set "ext=!platforms[%%i].ext!"
    set "suffix=!platforms[%%i].suffix!"
    
    echo.
    echo !%LANG%_MESSAGES[6]! !os! !arch!...
    
    set GOOS=!os!
    set GOARCH=!arch!
    
    :: 构建输出文件名 / Build output filename
    set "outfile=..\bin\cursor_id_modifier_v%VERSION%_!os!_!arch!!suffix!!ext!"
    
    :: 执行构建 / Execute build
    go build -trimpath -buildmode=%BUILDMODE% -ldflags="%LDFLAGS%" -gcflags="%GCFLAGS%" -o "!outfile!" ..\main.go
    
    if !errorlevel! equ 0 (
        echo %GREEN%!%LANG%_MESSAGES[7]! !outfile!%RESET%
    ) else (
        echo %RED%!%LANG%_MESSAGES[8]! !os! !arch!%RESET%
    )
)

:: 计算总耗时 / Calculate total time
set end_time=%time%
set /a duration = %end_time:~0,2% * 3600 + %end_time:~3,2% * 60 + %end_time:~6,2% - (%start_time:~0,2% * 3600 + %start_time:~3,2% * 60 + %start_time:~6,2%)

echo.
echo %GREEN%!%LANG%_MESSAGES[9]! %duration% !%LANG%_MESSAGES[10]!%RESET%
if exist "..\bin" dir /b "..\bin"

pause
endlocal