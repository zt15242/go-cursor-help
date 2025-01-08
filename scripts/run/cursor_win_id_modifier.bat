@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: 颜色定义
set "RED=[31m"
set "GREEN=[32m"
set "YELLOW=[33m"
set "BLUE=[34m"
set "NC=[0m"

:: 配置文件路径
set "STORAGE_FILE=%APPDATA%\Cursor\User\globalStorage\storage.json"
set "BACKUP_DIR=%APPDATA%\Cursor\User\globalStorage\backups"

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo %RED%[错误]%NC% 请以管理员身份运行此脚本
    echo 请右键点击脚本，选择"以管理员身份运行"
    pause
    exit /b 1
)

:: 显示 Logo
cls
echo.
echo     ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
echo    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
echo    ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
echo    ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
echo    ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
echo     ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
echo.
echo %BLUE%================================%NC%
echo %GREEN%      Cursor ID 修改工具%NC%
echo %BLUE%================================%NC%
echo.

:: 检查并关闭 Cursor 进程
:: 定义最大重试次数和等待时间
set "MAX_RETRIES=5"
set "WAIT_TIME=1"

echo %GREEN%[信息]%NC% 检查 Cursor 进程...

goto :main

:check_process
setlocal
set "process_name=%~1"
tasklist /FI "IMAGENAME eq %process_name%" 2>NUL | find /I "%process_name%" >NUL
endlocal & exit /b %ERRORLEVEL%

:get_process_details
setlocal
set "process_name=%~1"
echo %BLUE%[调试]%NC% 正在获取 %process_name% 进程详细信息：
wmic process where "name='%process_name%'" get ProcessId,ExecutablePath,CommandLine /format:list
endlocal
exit /b

:main

:: 处理 Cursor.exe
call :check_process "Cursor.exe"
if %ERRORLEVEL% equ 0 (
    echo %YELLOW%[警告]%NC% 发现 Cursor.exe 正在运行
    call :get_process_details "Cursor.exe"
    
    echo %YELLOW%[警告]%NC% 尝试关闭 Cursor.exe...
    taskkill /F /IM "Cursor.exe" >NUL 2>&1
    
    :: 循环检测进程是否真正关闭
    set "retry_count=0"
    :retry_cursor
    call :check_process "Cursor.exe"
    if %ERRORLEVEL% equ 0 (
        set /a "retry_count+=1"
        if !retry_count! geq %MAX_RETRIES% (
            echo %RED%[错误]%NC% 在 %MAX_RETRIES% 次尝试后仍无法关闭 Cursor.exe
            call :get_process_details "Cursor.exe"
            echo %RED%[错误]%NC% 请手动关闭进程后重试
            pause
            exit /b 1
        )
        echo %YELLOW%[警告]%NC% 等待进程关闭，尝试 !retry_count!/%MAX_RETRIES%...
        timeout /t %WAIT_TIME% /nobreak >NUL
        goto retry_cursor
    )
    echo %GREEN%[信息]%NC% Cursor.exe 已成功关闭
)

:: 处理 cursor.exe
call :check_process "cursor.exe"
if %ERRORLEVEL% equ 0 (
    echo %YELLOW%[警告]%NC% 发现 cursor.exe 正在运行
    call :get_process_details "cursor.exe"
    
    echo %YELLOW%[警告]%NC% 尝试关闭 cursor.exe...
    taskkill /F /IM "cursor.exe" >NUL 2>&1
    
    :: 循环检测进程是否真正关闭
    set "retry_count=0"
    :retry_cursor_lower
    call :check_process "cursor.exe"
    if %ERRORLEVEL% equ 0 (
        set /a "retry_count+=1"
        if !retry_count! geq %MAX_RETRIES% (
            echo %RED%[错误]%NC% 在 %MAX_RETRIES% 次尝试后仍无法关闭 cursor.exe
            call :get_process_details "cursor.exe"
            echo %RED%[错误]%NC% 请手动关闭进程后重试
            pause
            exit /b 1
        )
        echo %YELLOW%[警告]%NC% 等待进程关闭，尝试 !retry_count!/%MAX_RETRIES%...
        timeout /t %WAIT_TIME% /nobreak >NUL
        goto retry_cursor_lower
    )
    echo %GREEN%[信息]%NC% cursor.exe 已成功关闭
)

:: 最终确认所有进程都已关闭
echo %GREEN%[信息]%NC% 正在进行最终确认...
call :check_process "Cursor.exe"
if %ERRORLEVEL% equ 0 (
    echo %RED%[错误]%NC% 仍然检测到 Cursor.exe 进程
    call :get_process_details "Cursor.exe"
    pause
    exit /b 1
)
call :check_process "cursor.exe"
if %ERRORLEVEL% equ 0 (
    echo %RED%[错误]%NC% 仍然检测到 cursor.exe 进程
    call :get_process_details "cursor.exe"
    pause
    exit /b 1
)

echo %GREEN%[信息]%NC% 所有 Cursor 进程已确认关闭

:: 创建备份目录
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: 备份现有配置
if exist "%STORAGE_FILE%" (
    echo %GREEN%[信息]%NC% 正在备份配置文件...
    copy "%STORAGE_FILE%" "%BACKUP_DIR%\storage.json.backup_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%" >NUL
    if !errorlevel! neq 0 (
        echo %RED%[错误]%NC% 备份失败
        pause
        exit /b 1
    )
)

:: 生成新的 ID
echo %GREEN%[信息]%NC% 正在生成新的 ID...

:: 生成随机 ID
for /f "delims=" %%a in ('powershell -Command "[System.Guid]::NewGuid().ToString()"') do set "UUID=%%a"
for /f "delims=" %%a in ('powershell -Command "$bytes = New-Object Byte[] 32; (New-Object Security.Cryptography.RNGCryptoServiceProvider).GetBytes($bytes); -join($bytes | ForEach-Object { $_.ToString('x2') })"') do set "MACHINE_ID=%%a"
for /f "delims=" %%a in ('powershell -Command "$bytes = New-Object Byte[] 32; (New-Object Security.Cryptography.RNGCryptoServiceProvider).GetBytes($bytes); -join($bytes | ForEach-Object { $_.ToString('x2') })"') do set "MAC_MACHINE_ID=%%a"
for /f "delims=" %%a in ('powershell -Command "[System.Guid]::NewGuid().ToString().ToUpper()"') do set "SQM_ID={%%a}"

:: 创建或更新配置文件
echo %GREEN%[信息]%NC% 正在更新配置...

:: 直接更新 JSON 文件
if not exist "%STORAGE_FILE%" (
    echo {> "%STORAGE_FILE%"
    echo     "telemetry.machineId": "%MACHINE_ID%",>> "%STORAGE_FILE%"
    echo     "telemetry.macMachineId": "%MAC_MACHINE_ID%",>> "%STORAGE_FILE%"
    echo     "telemetry.devDeviceId": "%UUID%",>> "%STORAGE_FILE%"
    echo     "telemetry.sqmId": "%SQM_ID%">> "%STORAGE_FILE%"
    echo }>> "%STORAGE_FILE%"
) else (
    :: 使用 PowerShell 更新现有 JSON 文件
    powershell -Command "$json = Get-Content '%STORAGE_FILE%' | ConvertFrom-Json; $json.'telemetry.machineId' = '%MACHINE_ID%'; $json.'telemetry.macMachineId' = '%MAC_MACHINE_ID%'; $json.'telemetry.devDeviceId' = '%UUID%'; $json.'telemetry.sqmId' = '%SQM_ID%'; $json | ConvertTo-Json -Depth 10 | Set-Content '%STORAGE_FILE%'"
)

:: 设置文件权限
icacls "%STORAGE_FILE%" /grant:r "%USERNAME%":F >NUL

:: 显示结果
echo.
echo %GREEN%[信息]%NC% 已更新配置:
echo %BLUE%[调试]%NC% machineId: %MACHINE_ID%
echo %BLUE%[调试]%NC% macMachineId: %MAC_MACHINE_ID%
echo %BLUE%[调试]%NC% devDeviceId: %UUID%
echo %BLUE%[调试]%NC% sqmId: %SQM_ID%
echo.
echo %GREEN%[信息]%NC% 操作完成！

:: 显示公众号信息
echo.
echo %GREEN%================================%NC%
echo %YELLOW%  关注公众号【煎饼果子AI】一起交流更多Cursor技巧和AI知识  %NC%
echo %GREEN%================================%NC%
echo.

:: 显示文件树结构
echo.
echo %GREEN%[信息]%NC% 文件结构:
echo %BLUE%%APPDATA%\Cursor\User%NC%
echo ├── globalStorage
echo │   ├── storage.json (已修改)
echo │   └── backups

:: 列出备份文件
if exist "%BACKUP_DIR%\*" (
    for %%F in ("%BACKUP_DIR%\*") do (
        echo │       └── %%~nxF
    )
) else (
    echo │       └── (空)
)
echo.

echo %GREEN%[信息]%NC% 请重启 Cursor 以应用新的配置

echo.

pause
exit /b 0
