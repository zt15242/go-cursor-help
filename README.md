# 🚀 Cursor Free Trial Reset Tool

<div align="center">

[![Release](https://img.shields.io/github/v/release/yuaotian/go-cursor-help?style=flat-square&logo=github&color=blue)](https://github.com/yuaotian/go-cursor-help/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=bookstack)](https://github.com/yuaotian/go-cursor-help/blob/main/LICENSE)
[![Stars](https://img.shields.io/github/stars/yuaotian/go-cursor-help?style=flat-square&logo=github)](https://github.com/yuaotian/go-cursor-help/stargazers)

[English](#-english) | [中文](#-chinese)

<img src="https://ai-cursor.com/wp-content/uploads/2024/09/logo-cursor-ai-png.webp" alt="Cursor Logo" width="120"/>

</div>

# 🌟 English

### 📝 Description

Resets Cursor's free trial limitation when you see:

```
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
```

### 💻 System Support

**Windows** ✅ AMD64 & ARM64  
**macOS** ✅ AMD64 & ARM64  
**Linux** ✅ AMD64 & ARM64

### 📥 Installation

**Linux/macOS**
```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/master/install.sh | bash
```

**Windows** (Run in PowerShell as Admin)
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; $arch = if ([Environment]::Is64BitOperatingSystem) { if ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -eq 'Arm64') { 'arm64' } else { 'amd64' } } else { 'amd64' }; $ver = (irm https://api.github.com/repos/yuaotian/go-cursor-help/releases/latest).tag_name.TrimStart('v'); $outfile = "$env:TEMP\cursor_id_modifier.exe"; irm "https://github.com/yuaotian/go-cursor-help/releases/download/v${ver}/cursor_id_modifier_${ver}_windows_${arch}.exe" -OutFile $outfile; & $outfile; Remove-Item -Path $outfile -ErrorAction SilentlyContinue
```

### 🔧 Technical Details

The program modifies Cursor's `storage.json` config file:
- Windows: `%APPDATA%\Cursor\User\globalStorage\`
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/`
- Linux: `~/.config/Cursor/User/globalStorage/`

Generates new unique identifiers for:
- `telemetry.machineId`
- `telemetry.macMachineId`
- `telemetry.devDeviceId`
- `telemetry.sqmId`

---

# 🌏 Chinese

### 📝 问题描述

当看到以下提示时重置Cursor试用期：

```
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
```

### 💻 系统支持

**Windows** ✅ AMD64和ARM64  
**macOS** ✅ AMD64和ARM64  
**Linux** ✅ AMD64和ARM64

### 📥 安装方法

**Linux/macOS**
```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/master/install.sh | bash
```

**Windows** (以管理员身份运行PowerShell)
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; $arch = if ([Environment]::Is64BitOperatingSystem) { if ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -eq 'Arm64') { 'arm64' } else { 'amd64' } } else { 'amd64' }; $ver = (irm https://api.github.com/repos/yuaotian/go-cursor-help/releases/latest).tag_name.TrimStart('v'); $outfile = "$env:TEMP\cursor_id_modifier.exe"; irm "https://github.com/yuaotian/go-cursor-help/releases/download/v${ver}/cursor_id_modifier_${ver}_windows_${arch}.exe" -OutFile $outfile; & $outfile; Remove-Item -Path $outfile -ErrorAction SilentlyContinue
```

### 🔧 技术细节

程序修改Cursor的`storage.json`配置文件：
- Windows: `%APPDATA%\Cursor\User\globalStorage\`
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/`
- Linux: `~/.config/Cursor/User/globalStorage/`

生成新的唯一标识符：
- `telemetry.machineId`
- `telemetry.macMachineId`
- `telemetry.devDeviceId`
- `telemetry.sqmId`

## 📄 License

MIT License

Copyright (c) 2024
