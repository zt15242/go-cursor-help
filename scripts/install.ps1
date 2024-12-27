# Auto-elevate to admin rights if not already running as admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting administrator privileges..."
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -ExecutionFromElevated"
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    Exit
}

# Set TLS to 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Blue = "`e[36m"
$Yellow = "`e[33m"
$Reset = "`e[0m"

# Create temporary directory
$TmpDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $TmpDir | Out-Null

# Cleanup function
function Cleanup {
    if (Test-Path $TmpDir) {
        Remove-Item -Recurse -Force $TmpDir
    }
}

# Error handler
trap {
    Write-Host "${Red}Error: $_${Reset}"
    Cleanup
    exit 1
}

# Detect system architecture
function Get-SystemArch {
    if ([Environment]::Is64BitOperatingSystem) {
        return "amd64"
    } else {
        return "386"
    }
}

# Download with progress
function Download-WithProgress {
    param (
        [string]$Url,
        [string]$OutputFile
    )
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PowerShell Script")
        
        $webClient.DownloadFile($Url, $OutputFile)
        return $true
    }
    catch {
        Write-Host "${Red}Failed to download: $_${Reset}"
        return $false
    }
}

# Main installation function
function Install-CursorModifier {
    Write-Host "${Blue}Starting installation...${Reset}"
    
    # Detect architecture
    $arch = Get-SystemArch
    Write-Host "${Green}Detected architecture: $arch${Reset}"
    
    # Set installation directory
    $InstallDir = "$env:ProgramFiles\CursorModifier"
    if (!(Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir | Out-Null
    }
    
    # Get latest release
    try {
        $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/dacrab/cursor-id-modifier/releases/latest"
        $downloadUrl = $latestRelease.assets | Where-Object { $_.name -match "windows_$arch" } | Select-Object -ExpandProperty browser_download_url
        
        if (!$downloadUrl) {
            throw "Could not find download URL for windows_$arch"
        }
    }
    catch {
        Write-Host "${Red}Failed to get latest release: $_${Reset}"
        exit 1
    }
    
    # Download binary
    Write-Host "${Blue}Downloading latest release...${Reset}"
    $binaryPath = Join-Path $TmpDir "cursor-id-modifier.exe"
    
    if (!(Download-WithProgress -Url $downloadUrl -OutputFile $binaryPath)) {
        exit 1
    }
    
    # Install binary
    Write-Host "${Blue}Installing...${Reset}"
    try {
        Copy-Item -Path $binaryPath -Destination "$InstallDir\cursor-id-modifier.exe" -Force
        
        # Add to PATH if not already present
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        if ($currentPath -notlike "*$InstallDir*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$InstallDir", "Machine")
        }
    }
    catch {
        Write-Host "${Red}Failed to install: $_${Reset}"
        exit 1
    }
    
    Write-Host "${Green}Installation completed successfully!${Reset}"
    Write-Host "${Blue}You can now run: cursor-id-modifier${Reset}"
}

# Run installation
try {
    Install-CursorModifier
}
finally {
    Cleanup
}