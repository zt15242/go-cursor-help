# Auto-elevate to admin rights if not already running as admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting administrator privileges..."
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -ExecutionFromElevated"
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    Exit
}

# Set TLS to 1.2 / 设置 TLS 为 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Colors for output / 输出颜色
$Red = "`e[31m"
$Green = "`e[32m"
$Blue = "`e[36m"
$Yellow = "`e[33m"
$Reset = "`e[0m"

# Messages / 消息
$EN_MESSAGES = @(
    "Starting installation...",
    "Detected architecture:",
    "Only 64-bit Windows is supported",
    "Latest version:",
    "Creating installation directory...",
    "Downloading latest release from:",
    "Failed to download binary:",
    "Downloaded file not found",
    "Installing binary...",
    "Failed to install binary:",
    "Adding to PATH...",
    "Cleaning up...",
    "Installation completed successfully!",
    "You can now use 'cursor-id-modifier' directly",
    "Checking for running Cursor instances...",
    "Found running Cursor processes. Attempting to close them...",
    "Successfully closed all Cursor instances",
    "Failed to close Cursor instances. Please close them manually",
    "Backing up storage.json...",
    "Backup created at:"
)

$CN_MESSAGES = @(
    "开始安装...",
    "检测到架构：",
    "仅支持64位Windows系统",
    "最新版本：",
    "正在创建安装目录...",
    "正在从以下地址下载最新版本：",
    "下载二进制文件失败：",
    "未找到下载的文件",
    "正在安装程序...",
    "安装二进制文件失败：",
    "正在添加到PATH...",
    "正在清理...",
    "安装成功完成！",
    "现在可以直接使用 'cursor-id-modifier' 了",
    "正在检查运行中的Cursor进程...",
    "发现正在运行的Cursor进程，尝试关闭...",
    "成功关闭所有Cursor实例",
    "无法关闭Cursor实例，请手动关闭",
    "正在备份storage.json...",
    "备份已创建于："
)

# Detect system language / 检测系统语言
function Get-SystemLanguage {
    if ((Get-Culture).Name -like "zh-CN") {
        return "cn"
    }
    return "en"
}

# Get message based on language / 根据语言获取消息
function Get-Message($Index) {
    $lang = Get-SystemLanguage
    if ($lang -eq "cn") {
        return $CN_MESSAGES[$Index]
    }
    return $EN_MESSAGES[$Index]
}

# Functions for colored output / 彩色输出函数
function Write-Status($Message) {
    Write-Host "${Blue}[*]${Reset} $Message"
}

function Write-Success($Message) {
    Write-Host "${Green}[✓]${Reset} $Message"
}

function Write-Warning($Message) {
    Write-Host "${Yellow}[!]${Reset} $Message"
}

function Write-Error($Message) {
    Write-Host "${Red}[✗]${Reset} $Message"
    Exit 1
}

# Close Cursor instances / 关闭Cursor实例
function Close-CursorInstances {
    Write-Status (Get-Message 14)
    $cursorProcesses = Get-Process "Cursor" -ErrorAction SilentlyContinue
    
    if ($cursorProcesses) {
        Write-Status (Get-Message 15)
        try {
            $cursorProcesses | ForEach-Object { $_.CloseMainWindow() | Out-Null }
            Start-Sleep -Seconds 2
            $cursorProcesses | Where-Object { !$_.HasExited } | Stop-Process -Force
            Write-Success (Get-Message 16)
        } catch {
            Write-Error (Get-Message 17)
        }
    }
}

# Backup storage.json / 备份storage.json
function Backup-StorageJson {
    Write-Status (Get-Message 18)
    $storageJsonPath = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
    if (Test-Path $storageJsonPath) {
        $backupPath = "$storageJsonPath.backup"
        Copy-Item -Path $storageJsonPath -Destination $backupPath -Force
        Write-Success "$(Get-Message 19) $backupPath"
    }
}

# Get latest release version from GitHub / 从GitHub获取最新版本
function Get-LatestVersion {
    $repo = "yuaotian/go-cursor-help"
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest"
    return $release.tag_name
}

# 在文件开头添加日志函数
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    $logFile = "$env:TEMP\cursor-id-modifier-install.log"
    Add-Content -Path $logFile -Value $logMessage
    
    # 同时输出到控制台
    switch ($Level) {
        "ERROR" { Write-Error $Message }
        "WARNING" { Write-Warning $Message }
        "SUCCESS" { Write-Success $Message }
        default { Write-Status $Message }
    }
}

# 添加安装前检查函数
function Test-Prerequisites {
    Write-Log "Checking prerequisites..." "INFO"
    
    # 检查PowerShell版本
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Log "PowerShell 5.0 or higher is required" "ERROR"
        return $false
    }
    
    # 检查网络连接
    try {
        $testConnection = Test-Connection -ComputerName "github.com" -Count 1 -Quiet
        if (-not $testConnection) {
            Write-Log "No internet connection available" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Failed to check internet connection: $_" "ERROR"
        return $false
    }
    
    return $true
}

# 添加文件验证函数
function Test-FileHash {
    param(
        [string]$FilePath,
        [string]$ExpectedHash
    )
    
    $actualHash = Get-FileHash -Path $FilePath -Algorithm SHA256
    return $actualHash.Hash -eq $ExpectedHash
}

# 修改下载函数，添加进度条
function Download-File {
    param(
        [string]$Url,
        [string]$OutFile
    )
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PowerShell Script")
        
        $webClient.DownloadFileAsync($Url, $OutFile)
        
        while ($webClient.IsBusy) {
            Write-Progress -Activity "Downloading..." -Status "Progress:" -PercentComplete -1
            Start-Sleep -Milliseconds 100
        }
        
        Write-Progress -Activity "Downloading..." -Completed
        return $true
    }
    catch {
        Write-Log "Download failed: $_" "ERROR"
        return $false
    }
    finally {
        if ($webClient) {
            $webClient.Dispose()
        }
    }
}

# Main installation process / 主安装过程
Write-Status (Get-Message 0)

# Close any running Cursor instances
Close-CursorInstances

# Backup storage.json
Backup-StorageJson

# Get system architecture / 获取系统架构
$arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }
Write-Status "$(Get-Message 1) $arch"

if ($arch -ne "amd64") {
    Write-Error (Get-Message 2)
}

# Get latest version / 获取最新版本
$version = Get-LatestVersion
Write-Status "$(Get-Message 3) $version"

# Set up paths / 设置路径
$installDir = "$env:ProgramFiles\cursor-id-modifier"
$versionWithoutV = $version.TrimStart('v')  # 移除版本号前面的 'v' 字符
$binaryName = "cursor_id_modifier_${versionWithoutV}_windows_amd64.exe"
$downloadUrl = "https://github.com/yuaotian/go-cursor-help/releases/download/$version/$binaryName"
$tempFile = "$env:TEMP\$binaryName"

# Create installation directory / 创建安装目录
Write-Status (Get-Message 4)
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# Download binary / 下载二进制文件
Write-Status "$(Get-Message 5) $downloadUrl"
try {
    if (-not (Download-File -Url $downloadUrl -OutFile $tempFile)) {
        Write-Error "$(Get-Message 6)"
    }
} catch {
    Write-Error "$(Get-Message 6) $_"
}

# Verify download / 验证下载
if (-not (Test-Path $tempFile)) {
    Write-Error (Get-Message 7)
}

# Install binary / 安装二进制文件
Write-Status (Get-Message 8)
try {
    Move-Item -Force $tempFile "$installDir\cursor-id-modifier.exe"
} catch {
    Write-Error "$(Get-Message 9) $_"
}

# Add to PATH if not already present / 如果尚未添加则添加到PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$installDir*") {
    Write-Status (Get-Message 10)
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$userPath;$installDir",
        "User"
    )
}

# Cleanup / 清理
Write-Status (Get-Message 11)
if (Test-Path $tempFile) {
    Remove-Item -Force $tempFile
}

Write-Success (Get-Message 12)
Write-Success (Get-Message 13)
Write-Host ""

# 直接运行程序
try {
    Start-Process "$installDir\cursor-id-modifier.exe" -NoNewWindow
} catch {
    Write-Warning "Failed to start cursor-id-modifier: $_"
}