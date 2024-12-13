@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: 版本号
set "VERSION=2.0.0"

:: 检测语言
for /f "tokens=2 delims==" %%a in ('wmic os get OSLanguage /value') do set OSLanguage=%%a
if "%OSLanguage%"=="2052" (
    set "LANG=cn"
) else (
    set "LANG=en"
)

:: 多语言文本
if "%LANG%"=="cn" (
    set "SUCCESS_MSG=[√] 配置文件已成功更新！"
    set "RESTART_MSG=[!] 请手动重启 Cursor 以使更新生效"
    set "READING_CONFIG=正在读取配置文件..."
    set "GENERATING_IDS=正在生成新的标识符..."
    set "CHECKING_PROCESSES=正在检查运行中的 Cursor 实例..."
    set "CLOSING_PROCESSES=正在关闭 Cursor 实例..."
    set "PROCESSES_CLOSED=所有 Cursor 实例已关闭"
    set "PLEASE_WAIT=请稍候..."
) else (
    set "SUCCESS_MSG=[√] Configuration file updated successfully!"
    set "RESTART_MSG=[!] Please restart Cursor manually for changes to take effect"
    set "READING_CONFIG=Reading configuration file..."
    set "GENERATING_IDS=Generating new identifiers..."
    set "CHECKING_PROCESSES=Checking for running Cursor instances..."
    set "CLOSING_PROCESSES=Closing Cursor instances..."
    set "PROCESSES_CLOSED=All Cursor instances have been closed"
    set "PLEASE_WAIT=Please wait..."
)

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 请以管理员身份运行此脚本
    echo Please run this script as administrator
    pause
    exit /b 1
)

:: 主程序
:main
cls
call :printBanner

echo %CHECKING_PROCESSES%
tasklist | find /i "Cursor.exe" >nul
if %errorLevel% equ 0 (
    echo %CLOSING_PROCESSES%
    taskkill /F /IM "Cursor.exe" >nul 2>&1
    timeout /t 2 >nul
    echo %PROCESSES_CLOSED%
)

set "CONFIG_PATH=%APPDATA%\Cursor\User\globalStorage\storage.json"
echo %READING_CONFIG%

echo %GENERATING_IDS%
:: 生成随机ID
set "machineId="
set "macMachineId="
set "devDeviceId="
set "sqmId="

:: 生成32位随机ID
for /L %%i in (1,1,32) do (
    set /a "r=!random! %% 16"
    set "hex=0123456789abcdef"
    for %%j in (!r!) do set "machineId=!machineId!!hex:~%%j,1!"
)

for /L %%i in (1,1,32) do (
    set /a "r=!random! %% 16"
    for %%j in (!r!) do set "macMachineId=!macMachineId!!hex:~%%j,1!"
)

:: 生成UUID格式的devDeviceId
for /L %%i in (1,1,32) do (
    set /a "r=!random! %% 16"
    for %%j in (!r!) do set "devDeviceId=!devDeviceId!!hex:~%%j,1!"
    if %%i==8 set "devDeviceId=!devDeviceId!-"
    if %%i==12 set "devDeviceId=!devDeviceId!-"
    if %%i==16 set "devDeviceId=!devDeviceId!-"
    if %%i==20 set "devDeviceId=!devDeviceId!-"
)

for /L %%i in (1,1,32) do (
    set /a "r=!random! %% 16"
    for %%j in (!r!) do set "sqmId=!sqmId!!hex:~%%j,1!"
)

:: 创建配置目录
if not exist "%APPDATA%\Cursor\User\globalStorage" (
    mkdir "%APPDATA%\Cursor\User\globalStorage"
)

:: 生成配置文件
(
echo {
echo     "telemetry.macMachineId": "%macMachineId%",
echo     "telemetry.machineId": "%machineId%",
echo     "telemetry.devDeviceId": "%devDeviceId%",
echo     "telemetry.sqmId": "%sqmId%"
echo }
) > "%CONFIG_PATH%"

echo.
echo ============================================================
echo %SUCCESS_MSG%
echo %RESTART_MSG%
echo ============================================================
echo.
echo Config file location:
echo %CONFIG_PATH%
echo.
pause
exit /b

:: 打印banner
:printBanner
echo.
echo     ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗
echo    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
echo    ██║     ██║   ██║██████╔╝███████╗██║   ██║█████╔╝
echo    ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
echo    ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
echo     ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
echo.
echo              ^>^> Cursor ID Modifier v1.0 ^<^<
echo         [ By Pancake Fruit Rolled Shark Chili ]
echo.
exit /b

endlocal