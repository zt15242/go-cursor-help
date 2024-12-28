# Auto-elevate to admin rights if not already running as admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting administrator privileges..."
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -ExecutionFromElevated"
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    Exit
}

# Set TLS to 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
    Write-Host "Error: $_" -ForegroundColor Red
    Cleanup
    exit 1
}

# Detect system architecture
function Get-SystemArch {
    if ([Environment]::Is64BitOperatingSystem) {
        return "x64"
    } else {
        return "x86"
    }
}

# Download with progress
function Get-FileWithProgress {
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
        Write-Host "Failed to download: $_" -ForegroundColor Red
        return $false
    }
}

# Main installation function
function Install-CursorModifier {
    Write-Host "Starting installation..." -ForegroundColor Cyan
    
    # Detect architecture
    $arch = Get-SystemArch
    Write-Host "Detected architecture: $arch" -ForegroundColor Green
    
    # Set installation directory
    $InstallDir = "$env:ProgramFiles\CursorModifier"
    if (!(Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir | Out-Null
    }
    
    # Get latest release
    try {
        $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/dacrab/go-cursor-help/releases/latest"
        Write-Host "Found latest release: $($latestRelease.tag_name)" -ForegroundColor Cyan
        
        # Updated binary name format to match actual assets
        $binaryName = "cursor-id-modifier_windows_$arch.exe"
        Write-Host "Looking for asset: $binaryName" -ForegroundColor Cyan
        
        $asset = $latestRelease.assets | Where-Object { $_.name -eq $binaryName }
        $downloadUrl = $asset.browser_download_url
        
        if (!$downloadUrl) {
            Write-Host "Available assets:" -ForegroundColor Yellow
            $latestRelease.assets | ForEach-Object { Write-Host $_.name }
            throw "Could not find download URL for $binaryName"
        }
    }
    catch {
        Write-Host "Failed to get latest release: $_" -ForegroundColor Red
        exit 1
    }
    
    # Download binary
    Write-Host "Downloading latest release from $downloadUrl..." -ForegroundColor Cyan
    $binaryPath = Join-Path $TmpDir "cursor-id-modifier.exe"
    
    if (!(Get-FileWithProgress -Url $downloadUrl -OutputFile $binaryPath)) {
        exit 1
    }
    
    # Install binary
    Write-Host "Installing..." -ForegroundColor Cyan
    try {
        Copy-Item -Path $binaryPath -Destination "$InstallDir\cursor-id-modifier.exe" -Force
        
        # Add to PATH if not already present
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        if ($currentPath -notlike "*$InstallDir*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$InstallDir", "Machine")
        }
    }
    catch {
        Write-Host "Failed to install: $_" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Installation completed successfully!" -ForegroundColor Green
    Write-Host "Running cursor-id-modifier..." -ForegroundColor Cyan
    
    # Run the program
    try {
        & "$InstallDir\cursor-id-modifier.exe"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to run cursor-id-modifier" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "Failed to run cursor-id-modifier: $_" -ForegroundColor Red
        exit 1
    }
}

# Run installation
try {
    Install-CursorModifier
}
finally {
    Cleanup
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}