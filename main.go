package main

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
)

// StorageConfig 存储配置结构体
type StorageConfig struct {
	TelemetryMacMachineId string `json:"telemetry.macMachineId"`
	TelemetryMachineId    string `json:"telemetry.machineId"`
	TelemetryDevDeviceId  string `json:"telemetry.devDeviceId"`
}

// 生成类似原始machineId的字符串 (64位小写hex)
func generateMachineId() string {
	// 生成一些随机数据
	data := make([]byte, 32)
	rand.Read(data)

	// 使用SHA256生成hash
	hash := sha256.New()
	hash.Write(data)

	// 转换为小写的hex字符串
	return hex.EncodeToString(hash.Sum(nil))
}

// 生成类似原始macMachineId的字符串 (64位小写hex)
func generateMacMachineId() string {
	return generateMachineId() // 使用相同的格式
}

// 生成类似原始devDeviceId的字符串 (标准UUID格式)
func generateDevDeviceId() string {
	// 生成 UUID v4
	uuid := make([]byte, 16)
	rand.Read(uuid)

	// 设置版本 (4) 和变体位
	uuid[6] = (uuid[6] & 0x0f) | 0x40 // 版本 4
	uuid[8] = (uuid[8] & 0x3f) | 0x80 // RFC 4122 变体

	// 格式化为标准 UUID 字符串
	return fmt.Sprintf("%x-%x-%x-%x-%x",
		uuid[0:4],
		uuid[4:6],
		uuid[6:8],
		uuid[8:10],
		uuid[10:16])
}

// 获取配置文件路径
func getConfigPath() (string, error) {
	var configDir string
	switch runtime.GOOS {
	case "darwin":
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		configDir = filepath.Join(homeDir, "Library", "Application Support", "Cursor", "User", "globalStorage")
	case "windows":
		appData := os.Getenv("APPDATA")
		configDir = filepath.Join(appData, "Cursor", "User", "globalStorage")
	case "linux":
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		configDir = filepath.Join(homeDir, ".config", "Cursor", "User", "globalStorage")
	default:
		return "", fmt.Errorf("不支持的操作系统: %s", runtime.GOOS)
	}
	return filepath.Join(configDir, "storage.json"), nil
}

// 修改文件权限
func setFilePermissions(filePath string) error {
	if runtime.GOOS == "windows" {
		// Windows 使用 ACL 权限系统，这里仅设置为只读
		return os.Chmod(filePath, 0444)
	} else {
		// Linux 和 macOS
		return os.Chmod(filePath, 0444)
	}
}

// 获取Cursor可执行文件路径
func getCursorExePath() (string, error) {
	switch runtime.GOOS {
	case "windows":
		// Windows下通常在LocalAppData目录
		localAppData := os.Getenv("LOCALAPPDATA")
		return filepath.Join(localAppData, "Programs", "Cursor", "Cursor.exe"), nil
	case "darwin":
		// macOS下通常在Applications目录
		return "/Applications/Cursor.app/Contents/MacOS/Cursor", nil
	case "linux":
		// Linux下可能在usr/bin目录
		return "/usr/bin/cursor", nil
	default:
		return "", fmt.Errorf("不支持的操作系统: %s", runtime.GOOS)
	}
}



func main() {
	// 获取配置文件路径
	configPath, err := getConfigPath()
	if err != nil {
		fmt.Printf("获取配置文件路径失败: %v\n", err)
		return
	}

	// 读取原始文件内容
	content, err := os.ReadFile(configPath)
	if err != nil {
		fmt.Printf("读取配置文件失败: %v\n", err)
		return
	}

	// 解析 JSON
	var config map[string]interface{}
	if err := json.Unmarshal(content, &config); err != nil {
		fmt.Printf("解析 JSON 失败: %v\n", err)
		return
	}

	// 修改指定字段，使用更准确的生成方法
	config["telemetry.macMachineId"] = generateMacMachineId()
	config["telemetry.machineId"] = generateMachineId()
	config["telemetry.devDeviceId"] = generateDevDeviceId()

	// 转换回 JSON，保持原有的格式
	newContent, err := json.MarshalIndent(config, "", "    ")
	if err != nil {
		fmt.Printf("生成 JSON 失败: %v\n", err)
		return
	}

	// 先确保文件可写
	err = os.Chmod(configPath, 0666)
	if err != nil {
		fmt.Printf("修改文件权限失败: %v\n", err)
		return
	}

	// 写入文件
	err = os.WriteFile(configPath, newContent, 0666)
	if err != nil {
		fmt.Printf("写入文件失败: %v\n", err)
		return
	}

	// 设置文件为只读
	err = setFilePermissions(configPath)
	if err != nil {
		fmt.Printf("设置文件只读权限失败: %v\n", err)
		return
	}


	fmt.Println("配置文件已成功更新，请手动重启Cursor以使更改生效。")
}
