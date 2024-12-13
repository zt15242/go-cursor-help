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

**Windows** ✅ x64  
**macOS** ✅ Intel & M-series  
**Linux** ✅ x64 & ARM64

### 📥 Installation

#### Automatic Installation

**Linux/macOS**
```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/install.sh | bash -s -- --auto-sudo && rm -f /tmp/cursor_id_modifier_*
```

**Windows** (Run in PowerShell as Admin)
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/bin/cursor_id_modifier_v2.0.0_windows_amd64.exe')); Remove-Item -Path "$env:TEMP\cursor-id-modifier.exe" -ErrorAction SilentlyContinue
```

#### Manual Method

1. Close Cursor completely
2. Navigate to the configuration file location:
   - Windows: `%APPDATA%\Cursor\User\globalStorage\storage.json`
   - macOS: `~/Library/Application Support/Cursor/User/globalStorage/storage.json`
   - Linux: `~/.config/Cursor/User/globalStorage/storage.json`
3. Create a backup of `storage.json`
4. Edit `storage.json` and update these fields with new random UUIDs:
   ```json
   {
     "telemetry.machineId": "generate-new-uuid",
     "telemetry.macMachineId": "generate-new-uuid",
     "telemetry.devDeviceId": "generate-new-uuid",
     "telemetry.sqmId": "generate-new-uuid",
     "lastModified": "2024-01-01T00:00:00.000Z",
     "version": "2.0.0"
   }
   ```
5. Save the file and restart Cursor

#### Script Method (Alternative)

If you prefer using scripts directly, you can use these platform-specific scripts:

**For Linux/macOS:**
1. Download the [cursor_modifier.sh](scripts/cursor_modifier.sh)
2. Make it executable:
   ```bash
   chmod +x cursor_modifier.sh
   ```
3. Run with sudo:
   ```bash
   sudo ./cursor_modifier.sh
   ```

**For Windows:**
1. Download the [cursor_modifier.bat](scripts/cursor_modifier.bat)
2. Right-click and "Run as administrator"

These scripts will:
- Automatically detect system language (English/Chinese)
- Check for and close any running Cursor instances
- Generate new random IDs
- Update the configuration file
- Show the results with a nice UI

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

**Windows** ✅ x64  
**macOS** ✅ Intel和M系列  
**Linux** ✅ x64和ARM64

### 📥 安装方法

#### 自动安装

**Linux/macOS**
```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/install.sh | bash -s -- --auto-sudo && rm -f /tmp/cursor_id_modifier_*
```

**Windows** (以管理员身份运行PowerShell)
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/bin/cursor_id_modifier_v2.0.0_windows_amd64.exe')); Remove-Item -Path "$env:TEMP\cursor-id-modifier.exe" -ErrorAction SilentlyContinue
```

#### 手动方法

1. 完全关闭 Cursor
2. 找到配置文件位置：
   - Windows: `%APPDATA%\Cursor\User\globalStorage\storage.json`
   - macOS: `~/Library/Application Support/Cursor/User/globalStorage/storage.json`
   - Linux: `~/.config/Cursor/User/globalStorage/storage.json`
3. 备份 `storage.json`
4. 编辑 `storage.json` 并更新以下字段（使用新的随机UUID）：
   ```json
   {
     "telemetry.machineId": "生成新的uuid",
     "telemetry.macMachineId": "生成新的uuid",
     "telemetry.devDeviceId": "生成新的uuid",
     "telemetry.sqmId": "生成新的uuid",
     "lastModified": "2024-01-01T00:00:00.000Z",
     "version": "2.0.0"
   }
   ```
5. 保存文件并重启 Cursor

#### 脚本方法（替代方法）

如果您喜欢直接使用脚本，可以使用这些特定平台的脚本：

**适用于 Linux/macOS：**
1. 下载 [cursor_modifier.sh](scripts/cursor_modifier.sh)
2. 使其可执行：
   ```bash
   chmod +x cursor_modifier.sh
   ```
3. 用 sudo 运行
   ```bash
   sudo ./cursor_modifier.sh
   ```

**适用于 Windows：**
1. 下载 [cursor_modifier.bat]（脚本/cursor_modifier.bat）
2. 右键单击并 “以管理员身份运行”。

这些脚本将
- 自动检测系统语言（英语/中文）
- 检查并关闭任何正在运行的光标实例
- 生成新的随机 ID
- 更新配置文件
- 以漂亮的用户界面显示结果

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

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

