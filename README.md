# 🚀 Cursor Free Trial Reset Tool

<div align="center">

[![Release](https://img.shields.io/github/v/release/yuaotian/go-cursor-help?style=flat-square&logo=github&color=blue)](https://github.com/yuaotian/go-cursor-help/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=bookstack)](https://github.com/yuaotian/go-cursor-help/blob/master/LICENSE)
[![Stars](https://img.shields.io/github/stars/yuaotian/go-cursor-help?style=flat-square&logo=github)](https://github.com/yuaotian/go-cursor-help/stargazers)

[🌟 English](README.md) | [🌏 中文](README_CN.md)

<img src="https://ai-cursor.com/wp-content/uploads/2024/09/logo-cursor-ai-png.webp" alt="Cursor Logo" width="120"/>

</div>

---

### 📝 Description

> Resets Cursor's free trial limitation when you see: <p align="right"><a href="#issue1"><img src="https://img.shields.io/badge/Move%20to%20Solution-Blue?style=plastic" alt="Back To Top"></a></p>

```text
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
```

or <p align="right"><a href="#issue2"><img src="https://img.shields.io/badge/Move%20to%20Solution-green?style=plastic" alt="Back To Top"></a></p>

```text
[New Issue]

Composer relies on custom models that cannot be billed to an API key.
Please disable API keys and use a Pro or Business subscription.
Request ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

> If you see this message:This means you've reached the usage limit during the VIP free trial period.

```text
You've reached your trial request limit.
```

<br>

<p id="issue2"></p>

#### Solution 0: Uninstall Cursor Completely And Reinstall (API key Issue)

1. Download [Geek.exe Uninstaller[Free]](https://geekuninstaller.com/download)
2. Uninstall Cursor app completely
3. Re-Install Cursor app
4. Continue to Solution 1

<br>

<p id="issue1"></p>

> Temporary Solution:

#### Solution 1: Quick Reset (Recommended)

1. Close Cursor application
2. Run the machine code reset script (see installation instructions below)
3. Reopen Cursor to continue using

#### Solution 2: Account Switch

1. File -> Cursor Settings -> Sign Out
2. Close Cursor
3. Run the machine code reset script
4. Login with a new account

#### Solution 3: Network Optimization

If the above solutions don't work, try:

- Switch to low-latency nodes (Recommended regions: Japan, Singapore, US, Hong Kong)
- Ensure network stability
- Clear browser cache and retry

### 💻 System Support

<table>
<tr>
<td>

**Windows** ✅

- x64 (64-bit)
- x86 (32-bit)

</td>
<td>

**macOS** ✅

- Intel (x64)
- Apple Silicon (M1/M2)

</td>
<td>

**Linux** ✅

- x64 (64-bit)
- x86 (32-bit)
- ARM64

</td>
</tr>
</table>

### 🚀 One-Click Solution

<details open>
<summary><b>Global Users</b></summary>

**Linux/macOS**

```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/master/scripts/install.sh | sudo bash
```

**Windows**

```powershell
irm https://raw.githubusercontent.com/yuaotian/go-cursor-help/master/scripts/install.ps1 | iex
```

</details>

<details open>
<summary><b>China Users (Recommended)</b></summary>

**macOS**

```bash
curl -fsSL https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_mac_id_modifier.sh | sudo bash
```

**Linux**

```bash
curl -fsSL https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_linux_id_modifier.sh | sudo bash
```

**Windows**

```powershell
irm https://aizaozao.com/accelerate.php/https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/scripts/run/cursor_win_id_modifier.ps1 | iex
```

</details>

### 💻 如何打开 Windows 管理员终端

> **Windows 系统打开管理员终端的方法：**
>
> 1. 使用快捷键 `Win + X`
> 2. 在弹出的菜单中选择:
>    - "Windows PowerShell (管理员)"
>    - "Windows Terminal (管理员)"
>    - "终端(管理员)"
>      (根据系统版本可能显示不同选项)

### 🔧 PowerShell 安装指南

如果您的系统没有安装 PowerShell,可以通过以下方法安装:

#### 方法一：使用 Winget 安装（推荐）

1. 打开命令提示符或 PowerShell
2. 运行以下命令:
```powershell
winget install --id Microsoft.PowerShell --source winget
```

#### 方法二：手动下载安装

1. 下载对应系统的安装包:
   - [PowerShell-7.4.6-win-x64.msi](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi) (64位系统)
   - [PowerShell-7.4.6-win-x86.msi](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x86.msi) (32位系统)
   - [PowerShell-7.4.6-win-arm64.msi](https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-arm64.msi) (ARM64系统)

2. 双击下载的安装包,按提示完成安装

> 💡 如果仍然遇到问题,可以参考 [Microsoft 官方安装指南](https://learn.microsoft.com/zh-cn/powershell/scripting/install/installing-powershell-on-windows)

#### Windows 安装特性:

- 🔍 Automatically detects and uses PowerShell 7 if available
- 🛡️ Requests administrator privileges via UAC prompt
- 📝 Falls back to Windows PowerShell if PS7 isn't found
- 💡 Provides manual instructions if elevation fails

That's it! The script will:

1. ✨ Install the tool automatically
2. 🔄 Reset your Cursor trial immediately

### 📦 Manual Installation

> Download the appropriate file for your system from [releases](https://github.com/yuaotian/go-cursor-help/releases/latest)

<details>
<summary>Windows Packages</summary>

- 64-bit: `cursor-id-modifier_windows_x64.exe`
- 32-bit: `cursor-id-modifier_windows_x86.exe`
</details>

<details>
<summary>macOS Packages</summary>

- Intel: `cursor-id-modifier_darwin_x64_intel`
- M1/M2: `cursor-id-modifier_darwin_arm64_apple_silicon`
</details>

<details>
<summary>Linux Packages</summary>

- 64-bit: `cursor-id-modifier_linux_x64`
- 32-bit: `cursor-id-modifier_linux_x86`
- ARM64: `cursor-id-modifier_linux_arm64`
</details>

### 🔧 Technical Details

<details>
<summary><b>Configuration Files</b></summary>

The program modifies Cursor's `storage.json` config file located at:

- Windows: `%APPDATA%\Cursor\User\globalStorage\storage.json`
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/storage.json`
- Linux: `~/.config/Cursor/User/globalStorage/storage.json`
</details>

<details>
<summary><b>Modified Fields</b></summary>

The tool generates new unique identifiers for:

- `telemetry.machineId`
- `telemetry.macMachineId`
- `telemetry.devDeviceId`
- `telemetry.sqmId`
</details>

<details>
<summary><b>Manual Auto-Update Disable</b></summary>

Windows users can manually disable the auto-update feature:

1. Close all Cursor processes
2. Delete directory: `C:\Users\username\AppData\Local\cursor-updater`
3. Create a file with the same name: `cursor-updater` (without extension)

macOS/Linux users can try to locate similar `cursor-updater` directory in their system and perform the same operation.

</details>

<details>
<summary><b>Safety Features</b></summary>

- ✅ Safe process termination
- ✅ Atomic file operations
- ✅ Error handling and recovery
</details>

---

### 📚 Recommended Reading

- [Cursor Issues Collection and Solutions](https://mp.weixin.qq.com/s/pnJrH7Ifx4WZvseeP1fcEA)
- [AI Universal Development Assistant Prompt Guide](https://mp.weixin.qq.com/s/PRPz-qVkFJSgkuEKkTdzwg)

---

## ⭐ Project Stats

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=yuaotian/go-cursor-help&type=Date)](https://star-history.com/#yuaotian/go-cursor-help&Date)

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/ddaa9df9a94b0029ec3fad399e1c1c4e75755477.svg "Repobeats analytics image")

</div>

## 📄 License

<details>
<summary><b>MIT License</b></summary>

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

</details>
