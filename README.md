# 🚀 Cursor Free Trial Reset Tool

<div align="center">

[![Release](https://img.shields.io/github/v/release/dacrab/cursor-id-modifier?style=flat-square&logo=github&color=blue)](https://github.com/dacrab/cursor-id-modifier/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=bookstack)](https://github.com/dacrab/cursor-id-modifier/blob/main/LICENSE)
[![Stars](https://img.shields.io/github/stars/dacrab/cursor-id-modifier?style=flat-square&logo=github)](https://github.com/dacrab/cursor-id-modifier/stargazers)

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

**Windows** ✅
- x64 (64-bit)
- x86 (32-bit)

**macOS** ✅
- Intel (x64)
- Apple Silicon (M1/M2)

**Linux** ✅
- x64 (64-bit)
- x86 (32-bit)
- ARM64

### 📥 One-Click Solution

**Linux/macOS**: Copy and paste in terminal:
```bash
curl -fsSL https://raw.githubusercontent.com/dacrab/cursor-id-modifier/main/scripts/install.sh | sudo bash && cursor-id-modifier
```

**Windows**: Copy and paste in PowerShell (Admin):
```powershell
irm https://raw.githubusercontent.com/dacrab/cursor-id-modifier/main/scripts/install.ps1 | iex; cursor-id-modifier
```

That's it! The script will:
1. Install the tool automatically
2. Reset your Cursor trial immediately

### 🔧 Manual Installation

Download the appropriate file for your system from [releases](https://github.com/dacrab/cursor-id-modifier/releases/latest):

**Windows**:
- 64-bit: `cursor-id-modifier_vX.X.X_Windows_x64.zip`
- 32-bit: `cursor-id-modifier_vX.X.X_Windows_x86.zip`

**macOS**:
- Intel: `cursor-id-modifier_vX.X.X_macOS_x64_intel.tar.gz`
- M1/M2: `cursor-id-modifier_vX.X.X_macOS_arm64_apple_silicon.tar.gz`

**Linux**:
- 64-bit: `cursor-id-modifier_vX.X.X_Linux_x64.tar.gz`
- 32-bit: `cursor-id-modifier_vX.X.X_Linux_x86.tar.gz`
- ARM64: `cursor-id-modifier_vX.X.X_Linux_arm64.tar.gz`

### 🔧 Technical Details

#### Configuration Files
The program modifies Cursor's `storage.json` config file located at:
- Windows: `%APPDATA%\Cursor\User\globalStorage\storage.json`
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/storage.json`
- Linux: `~/.config/Cursor/User/globalStorage/storage.json`

#### Modified Fields
The tool generates new unique identifiers for:
- `telemetry.machineId`
- `telemetry.macMachineId`
- `telemetry.devDeviceId`
- `telemetry.sqmId`

#### Safety Features
- ✅ Safe process termination
- ✅ Atomic file operations
- ✅ Error handling and recovery

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

**Windows** ✅ x64 & x86  
**macOS** ✅ Intel & M-series  
**Linux** ✅ x64 & ARM64

### 📥 一键解决

**Linux/macOS**: 在终端中复制粘贴：
```bash
curl -fsSL https://raw.githubusercontent.com/dacrab/cursor-id-modifier/main/scripts/install.sh | sudo bash && cursor-id-modifier
```

**Windows**: 在PowerShell（管理员）中复制粘贴：
```powershell
irm https://raw.githubusercontent.com/dacrab/cursor-id-modifier/main/scripts/install.ps1 | iex; cursor-id-modifier
```

就这样！脚本会：
1. 自动安装工具
2. 立即重置Cursor试用期

### 🔧 技术细节

#### 配置文件
程序修改Cursor的`storage.json`配置文件，位于：
- Windows: `%APPDATA%\Cursor\User\globalStorage\`
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/`
- Linux: `~/.config/Cursor/User/globalStorage/`

#### 修改字段
工具会生成新的唯一标识符：
- `telemetry.machineId`
- `telemetry.macMachineId`
- `telemetry.devDeviceId`
- `telemetry.sqmId`

#### 安全特性
- ✅ 安全的进程终止
- ✅ 原子文件操作
- ✅ 错误处理和恢复

## ⭐ Star History or Repobeats

[![Star History Chart](https://api.star-history.com/svg?repos=yuaotian/go-cursor-help&type=Date)](https://star-history.com/#yuaotian/go-cursor-help&Date)


![Repobeats analytics image](https://repobeats.axiom.co/api/embed/ddaa9df9a94b0029ec3fad399e1c1c4e75755477.svg "Repobeats analytics image")


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

