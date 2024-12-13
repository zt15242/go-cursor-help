@echo off
setlocal EnableDelayedExpansion

:: 设置版本信息
set VERSION=2.5.0

:: 设置颜色代码
set "GREEN=[32m"
set "RED=[31m"
set "YELLOW=[33m"
set "RESET=[0m"
set "CYAN=[36m"

:: 设置编译优化标志
set "LDFLAGS=-s -w"
set "BUILDMODE=pie"
set "GCFLAGS=-N -l"

:: 设置 CGO
set CGO_ENABLED=0

:: 显示编译信息
echo %YELLOW%开始构建 version %VERSION%%RESET%
echo %YELLOW%使用优化标志: LDFLAGS=%LDFLAGS%, BUILDMODE=%BUILDMODE%%RESET%
echo %YELLOW%CGO_ENABLED=%CGO_ENABLED%%RESET%

:: 清理旧的构建文件
echo %YELLOW%清理旧的构建文件...%RESET%
if exist "..\bin" (
    rd /s /q "..\bin"
    echo %GREEN%清理完成%RESET%
) else (
    echo %YELLOW%bin 目录不存在，无需清理%RESET%
)

:: 创建输出目录
mkdir "..\bin" 2>nul

:: 定义目标平台数组
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

:: 设置开始时间
set start_time=%time%

:: 创建 MD5 信息文件
echo MD5 Checksums > ..\bin\md5_checksums.txt
echo ============= >> ..\bin\md5_checksums.txt
echo. >> ..\bin\md5_checksums.txt

:: 编译所有目标
echo 开始编译所有平台...

for /L %%i in (0,1,3) do (
    set "os=!platforms[%%i].os!"
    set "arch=!platforms[%%i].arch!"
    set "ext=!platforms[%%i].ext!"
    set "suffix=!platforms[%%i].suffix!"
    
    echo.
    echo Building for !os! !arch!...
    
    set GOOS=!os!
    set GOARCH=!arch!
    
    :: 构建输出文件名
    set "outfile=..\bin\cursor_id_modifier_v%VERSION%_!os!_!arch!!suffix!!ext!"
    
    :: 执行构建
    go build -trimpath -buildmode=%BUILDMODE% -ldflags="%LDFLAGS%" -gcflags="%GCFLAGS%" -o "!outfile!" ..\main.go
    
    if !errorlevel! equ 0 (
        echo %GREEN%Build successful: !outfile!%RESET%
        
        :: 计算并显示 MD5
        certutil -hashfile "!outfile!" MD5 | findstr /v "CertUtil" | findstr /v "MD5" > md5.tmp
        set /p MD5=<md5.tmp
        del md5.tmp
        echo !MD5! cursor_id_modifier_v%VERSION%_!os!_!arch!!suffix!!ext! >> ..\bin\md5_checksums.txt
        echo %CYAN%MD5: !MD5!%RESET%
    ) else (
        echo %RED%Build failed for !os! !arch!%RESET%
    )
)

:: 计算总耗时
set end_time=%time%
set /a duration = %end_time:~0,2% * 3600 + %end_time:~3,2% * 60 + %end_time:~6,2% - (%start_time:~0,2% * 3600 + %start_time:~3,2% * 60 + %start_time:~6,2%)

echo.
echo %GREEN%所有构建完成! 总耗时: %duration% 秒%RESET%
echo %CYAN%MD5 校验值已保存到 bin/md5_checksums.txt%RESET%
if exist "..\bin" dir /b "..\bin"

:: 显示 MD5 校验文件内容
echo.
echo %YELLOW%MD5 校验值:%RESET%
type ..\bin\md5_checksums.txt

pause
endlocal