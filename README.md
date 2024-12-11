# 🚀 Cursor Free Trial Reset Tool

<div align="center">

[![Release](https://img.shields.io/github/v/release/yuaotian/go-cursor-help?style=for-the-badge&logo=github&color=blue)](https://github.com/yuaotian/go-cursor-help/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge&logo=bookstack)](https://github.com/yuaotian/go-cursor-help/blob/main/LICENSE)
[![Stars](https://img.shields.io/github/stars/yuaotian/go-cursor-help?style=for-the-badge&logo=github)](https://github.com/yuaotian/go-cursor-help/stargazers)

[English](#english) | [中文](#chinese)

---

<img src="https://ai-cursor.com/wp-content/uploads/2024/09/logo-cursor-ai-png.webp" alt="Cursor Logo" width="150"/>

</div>

## ⚠️ Important Notice | 重要声明

<table>
<tr>
<td>

This tool is only intended for the following specific scenarios:
- 🕒 During Cursor's official free trial period
- 🔄 When system mistakenly flags as duplicate trial
- 🆘 As a temporary solution when official support is unavailable

**Please note:**
- 🚫 Not for bypassing paid features
- 💳 Purchase a license if trial expired
- 📞 Contact official support first
- ✅ Ensure valid trial period before use

</td>
</tr>
</table>

<a name="english"></a>
## 🌟 English

### 📝 Description
A tool to resolve the following prompt issue during Cursor's free trial period:
<table>
<tr>
<td>
<pre>
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
</pre>
</td>
</tr>
</table>

### ✨ Features
- 🔄 Reset Cursor free trial limitations
- 🔍 Automatic detection and closing of running instances
- 🌐 Cross-platform support with architecture detection
- 📦 Automated installation scripts
- 🖥️ Both GUI and command-line interfaces

### 💻 System Support
| Platform | Status |
|----------|---------|
| ![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat&logo=windows&logoColor=white) | ✅ x64 |
| ![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white) | ✅ Intel/Apple Silicon |
| ![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black) | ✅ x64/ARM64 |

### 📥 Installation Methods

<details open>
<summary><b>1️⃣ Automated Installation (Recommended)</b></summary>

#### Linux/macOS
```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/main/install.sh | sudo bash
```

#### Windows PowerShell
```powershell
# Download and run with admin privileges
$url = "https://github.com/yuaotian/go-cursor-help/releases/latest/download/cursor-id-modifier.exe"
$output = "$env:TEMP\cursor-id-modifier.exe"
Invoke-WebRequest -Uri $url -OutFile $output
Start-Process -FilePath $output -Verb RunAs
```
</details>

<details>
<summary><b>2️⃣ Manual Download</b></summary>

Download from [Releases](https://github.com/yuaotian/go-cursor-help/releases/latest):

| Platform | Architecture | File |
|----------|-------------|------|
| ![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat&logo=windows&logoColor=white) | x64 | `cursor-id-modifier.exe` |
| ![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white) | Intel (x64) | `cursor-id-modifier-amd64` |
| ![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white) | Apple Silicon | `cursor-id-modifier-arm64` |
| ![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black) | x64 | `cursor-id-modifier` |
| ![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black) | ARM64 | `cursor-id-modifier-arm64` |

</details>

### 📚 Usage Instructions

<details>
<summary>Prerequisites</summary>

- 👑 Administrator/root privileges required
- 🚫 Cursor should be completely closed
- 🌐 Internet connection for installation
</details>

<details>
<summary>Running the Tool</summary>

The tool will automatically:
1. 🔑 Check for and request admin privileges
2. 🔍 Detect and close Cursor instances
3. 💾 Backup existing configuration
4. 🔄 Generate new identifiers
5. ✅ Apply changes

Restart Cursor after completion.
</details>

### 🔧 Troubleshooting

<details>
<summary>Common Issues</summary>

#### 🚫 Permission Denied
- Windows: Right-click → "Run as Administrator"
- Linux/macOS: Use \`sudo\` when running

#### ⚠️ Cursor Still Running
- Tool will attempt auto-close
- Manual close via Task Manager if needed

#### 🔒 macOS Security
If you see "unidentified developer" warning:
1. Right-click → Open
2. Click "Open" in dialog
</details>

### ⚠️ Cautions
- 🛡️ Use at your own risk
- 💾 Backup important data
- 📚 Educational purposes only

### 🤝 Contributing
We welcome contributions! Please ensure:
- ✅ Cross-platform compatibility
- 🚫 No breaking changes
- 🔍 Proper error handling
- 📝 Documentation updates

---

<a name="chinese"></a>
## 🌏 中文

### 📝 问题描述
解决Cursor在免费订阅期间出现以下提示的问题:
<table>
<tr>
<td>
<pre>
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
</pre>
</td>
</tr>
</table>

### ✨ 功能特性
- 🔄 重置Cursor免费试用限制
- 🔍 自动检测和关闭运行中的实例
- 🌐 跨平台支持，自动检测系统架构
- 📦 自动化安装脚本
- 🖥️ 支持图形界面和命令行

### 💻 系统支持
| 平台 | 状态 |
|----------|---------|
| ![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat&logo=windows&logoColor=white) | ✅ x64 |
| ![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white) | ✅ Intel/Apple Silicon |
| ![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black) | ✅ x64/ARM64 |

### 📥 安装方法

<details open>
<summary><b>1️⃣ 自动安装（推荐）</b></summary>

#### Linux/macOS
```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/main/install.sh | sudo bash
```

#### Windows PowerShell
```powershell
# 下载并以管理员权限运行
$url = "https://github.com/yuaotian/go-cursor-help/releases/latest/download/cursor-id-modifier.exe"
$output = "$env:TEMP\cursor-id-modifier.exe"
Invoke-WebRequest -Uri $url -OutFile $output
Start-Process -FilePath $output -Verb RunAs
```
</details>

<details>
<summary><b>2️⃣ 手动下载</b></summary>

从[发布页面](https://github.com/yuaotian/go-cursor-help/releases/latest)下载：

| 平台 | 架构 | 文件 |
|----------|-------------|------|
| ![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat&logo=windows&logoColor=white) | x64 | `cursor-id-modifier.exe` |
| ![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white) | Intel (x64) | `cursor-id-modifier-amd64` |
| ![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white) | Apple Silicon | `cursor-id-modifier-arm64` |
| ![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black) | x64 | `cursor-id-modifier` |
| ![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black) | ARM64 | `cursor-id-modifier-arm64` |

</details>

### 📚 使用说明

<details>
<summary>使用前提</summary>

- 👑 需要管理员/root权限
- 🚫 确保Cursor完全关闭
- 🌐 需要网络连接进行安装
</details>

<details>
<summary>运行工具</summary>

工具将自动执行：
1. 🔑 检查并请求管理员权限
2. 🔍 检测并关闭Cursor进程
3. 💾 备份现有配置
4. 🔄 生成新的标识符
5. ✅ 应用更改

完成后重启Cursor即可。
</details>

### 🔧 故障排除

<details>
<summary>常见问题</summary>

#### 🚫 权限被拒绝
- Windows：右键 → "以管理员身份运行"
- Linux/macOS：使用 \`sudo\` 运行

#### ⚠️ Cursor仍在运行
- 工具会尝试自动关闭
- 如需要请通过任务管理器手动关闭

#### 🔒 macOS安全性问题
如果看到"未识别的开发者"提示：
1. 右键点击 → 打开
2. 点击确认对话框中的"打开"
</details>

### ⚠️ 注意事项
- 🛡️ 使用本工具需自行承担风险
- 💾 使用前请备份重要数据
- 📚 仅用于学习研究目的

### 🤝 贡献
欢迎提交问题和改进建议！请确保：
- ✅ 保持跨平台兼容性
- 🚫 避免破坏性更改
- 🔍 完善的错误处理
- 📝 更新相关文档

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