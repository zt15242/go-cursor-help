# 设置输出编码为 UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 颜色定义
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# 配置文件路径
$STORAGE_FILE = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
$BACKUP_DIR = "$env:APPDATA\Cursor\User\globalStorage\backups"

# 检查管理员权限
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "$RED[错误]$NC 请以管理员身份运行此脚本"
    Write-Host "请右键点击脚本，选择'以管理员身份运行'"
    Read-Host "按回车键退出"
    exit 1
}

# 显示 Logo
Clear-Host
Write-Host @"

    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝

"@
Write-Host "$BLUE================================$NC"
Write-Host "$GREEN      Cursor ID 修改工具          $NC"
Write-Host "$BLUE================================$NC"
Write-Host ""

# 检查并关闭 Cursor 进程
Write-Host "$GREEN[信息]$NC 检查 Cursor 进程..."

function Get-ProcessDetails {
    param($processName)
    Write-Host "$BLUE[调试]$NC 正在获取 $processName 进程详细信息："
    Get-WmiObject Win32_Process -Filter "name='$processName'" | 
        Select-Object ProcessId, ExecutablePath, CommandLine | 
        Format-List
}

# 定义最大重试次数和等待时间
$MAX_RETRIES = 5
$WAIT_TIME = 1

# 处理进程关闭
function Close-CursorProcess {
    param($processName)
    
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "$YELLOW[警告]$NC 发现 $processName 正在运行"
        Get-ProcessDetails $processName
        
        Write-Host "$YELLOW[警告]$NC 尝试关闭 $processName..."
        Stop-Process -Name $processName -Force
        
        $retryCount = 0
        while ($retryCount -lt $MAX_RETRIES) {
            $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if (-not $process) { break }
            
            $retryCount++
            if ($retryCount -ge $MAX_RETRIES) {
                Write-Host "$RED[错误]$NC 在 $MAX_RETRIES 次尝试后仍无法关闭 $processName"
                Get-ProcessDetails $processName
                Write-Host "$RED[错误]$NC 请手动关闭进程后重试"
                Read-Host "按回车键退出"
                exit 1
            }
            Write-Host "$YELLOW[警告]$NC 等待进程关闭，尝试 $retryCount/$MAX_RETRIES..."
            Start-Sleep -Seconds $WAIT_TIME
        }
        Write-Host "$GREEN[信息]$NC $processName 已成功关闭"
    }
}

# 关闭所有 Cursor 进程
Close-CursorProcess "Cursor"
Close-CursorProcess "cursor"

# 创建备份目录
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}

# 备份现有配置
if (Test-Path $STORAGE_FILE) {
    Write-Host "$GREEN[信息]$NC 正在备份配置文件..."
    $backupName = "storage.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $STORAGE_FILE "$BACKUP_DIR\$backupName"
}

# 生成新的 ID
Write-Host "$GREEN[信息]$NC 正在生成新的 ID..."

$UUID = [System.Guid]::NewGuid().ToString()
$MACHINE_ID = -join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
$MAC_MACHINE_ID = -join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
$SQM_ID = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"

# 创建或更新配置文件
Write-Host "$GREEN[信息]$NC 正在更新配置..."

$config = @{
    'telemetry.machineId' = $MACHINE_ID
    'telemetry.macMachineId' = $MAC_MACHINE_ID
    'telemetry.devDeviceId' = $UUID
    'telemetry.sqmId' = $SQM_ID
}

$config | ConvertTo-Json | Set-Content $STORAGE_FILE

# 设置文件权限
$acl = Get-Acl $STORAGE_FILE
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME, "FullControl", "Allow"
)
$acl.SetAccessRule($rule)
Set-Acl $STORAGE_FILE $acl

# 显示结果
Write-Host ""
Write-Host "$GREEN[信息]$NC 已更新配置:"
Write-Host "$BLUE[调试]$NC machineId: $MACHINE_ID"
Write-Host "$BLUE[调试]$NC macMachineId: $MAC_MACHINE_ID"
Write-Host "$BLUE[调试]$NC devDeviceId: $UUID"
Write-Host "$BLUE[调试]$NC sqmId: $SQM_ID"

# 显示公众号信息
Write-Host ""
Write-Host "$GREEN================================$NC"
Write-Host "$YELLOW  关注公众号【煎饼果子卷AI】一起交流更多Cursor技巧和AI知识  $NC"
Write-Host "$GREEN================================$NC"
Write-Host ""

# 显示文件树结构
Write-Host ""
Write-Host "$GREEN[信息]$NC 文件结构:"
Write-Host "$BLUE$env:APPDATA\Cursor\User$NC"
Write-Host "├── globalStorage"
Write-Host "│   ├── storage.json (已修改)"
Write-Host "│   └── backups"

# 列出备份文件
$backupFiles = Get-ChildItem "$BACKUP_DIR\*" -ErrorAction SilentlyContinue
if ($backupFiles) {
    foreach ($file in $backupFiles) {
        Write-Host "│       └── $($file.Name)"
    }
} else {
    Write-Host "│       └── (空)"
}
Write-Host ""

Write-Host "$GREEN[信息]$NC 请重启 Cursor 以应用新的配置"
Write-Host ""

Read-Host "按回车键退出"
exit 0 