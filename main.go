package main

import (
	"bufio"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/fatih/color"
)

// StorageConfig 存储配置结构体优化
type StorageConfig struct {
	TelemetryMacMachineId string `json:"telemetry.macMachineId"`
	TelemetryMachineId    string `json:"telemetry.machineId"`
	TelemetryDevDeviceId  string `json:"telemetry.devDeviceId"`
	LastModified          time.Time `json:"lastModified"`
	Version               string    `json:"version"`
}

// NewStorageConfig 创建新的配置实例
func NewStorageConfig() *StorageConfig {
	return &StorageConfig{
		TelemetryMacMachineId: generateMacMachineId(),
		TelemetryMachineId:    generateMachineId(),
		TelemetryDevDeviceId:  generateDevDeviceId(),
		LastModified:          time.Now(),
		Version:               "1.0.1",
	}
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

// 生成类似原始devDeviceId的字符 (标准UUID格式)
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

// 修改件权限
func setFilePermissions(filePath string) error {
	if runtime.GOOS == "windows" {
		// Windows 使用 ACL 权限系统，这里仅设置为只读
		return os.Chmod(filePath, 0444)
	} else {
		// Linux 和 macOS
		return os.Chmod(filePath, 0444)
	}
}


func printCyberpunkBanner() {
	cyan := color.New(color.FgCyan, color.Bold)
	yellow := color.New(color.FgYellow, color.Bold)
	magenta := color.New(color.FgMagenta, color.Bold)

	banner := `
    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
   ██║     ██║   ██║█╔══██╗╚════██║██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
    `
	cyan.Println(banner)
	yellow.Println("\t\t>> Cursor ID Modifier v1.0 <<")
	magenta.Println("\t\t   [ By Pancake Fruit Rolled Shark Chili ]")
}

type ProgressSpinner struct {
	frames  []string
	current int
	message string
}

func NewProgressSpinner(message string) *ProgressSpinner {
	return &ProgressSpinner{
		frames:  []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"},
		message: message,
	}
}

func (s *ProgressSpinner) Spin() {
	frame := s.frames[s.current%len(s.frames)]
	s.current++
	fmt.Printf("\r%s %s", color.CyanString(frame), s.message)
}

func (s *ProgressSpinner) Stop() {
	fmt.Println()
}

// 定义错误类型
type AppError struct {
	Op   string
	Path string
	Err  error
}

func (e *AppError) Error() string {
	if e.Path != "" {
		return fmt.Sprintf("%s: %v [路径: %s]", e.Op, e.Err, e.Path)
	}
	return fmt.Sprintf("%s: %v", e.Op, e.Err)
}

// 文件操作包装函数
func safeWriteFile(path string, data []byte, perm os.FileMode) error {
	// 创建临时文件
	tmpPath := path + ".tmp"
	if err := os.WriteFile(tmpPath, data, perm); err != nil {
		return &AppError{"写入临时文件", tmpPath, err}
	}
	
	// 重命名临时文件
	if err := os.Rename(tmpPath, path); err != nil {
		os.Remove(tmpPath) // 清理临时文件
		return &AppError{"重命名文件", path, err}
	}
	
	return nil
}



// clearScreen 清除终端屏幕
func clearScreen() {
	if runtime.GOOS == "windows" {
		cmd := exec.Command("cmd", "/c", "cls")
		cmd.Stdout = os.Stdout
		cmd.Run()
	} else {
		cmd := exec.Command("clear")
		cmd.Stdout = os.Stdout
		cmd.Run()
	}
}

// showProgress 显示进度
func showProgress(message string) {
	spinner := NewProgressSpinner(message)
	for i := 0; i < 15; i++ {
		spinner.Spin()
		time.Sleep(100 * time.Millisecond)
	}
	spinner.Stop()
}

// saveConfig 保存配置到文件
func saveConfig(config *StorageConfig) error {
	configPath, err := getConfigPath()
	if err != nil {
		return err
	}

	// 转换为JSON
	content, err := json.MarshalIndent(config, "", "    ")
	if err != nil {
		return &AppError{"生成JSON", "", err}
	}

	// 确保文件可写
	err = os.Chmod(configPath, 0666)
	if err != nil {
		return &AppError{"修改文件权限", configPath, err}
	}

	// 安全写入文件
	if err := safeWriteFile(configPath, content, 0666); err != nil {
		return err
	}

	// 设置为只读
	return setFilePermissions(configPath)
}

// showSuccess 显示成功信息
func showSuccess() {
	text := texts[currentLanguage]
	color.Green(text.SuccessMessage)
	color.Yellow(text.RestartMessage)
}

// 修改 loadAndUpdateConfig 函数使用 configPath
func loadAndUpdateConfig() (*StorageConfig, error) {
	configPath, err := getConfigPath()
	if err != nil {
		return nil, err
	}

	text := texts[currentLanguage]
	showProgress(text.ReadingConfig)
	
	// 读取原始文件内容
	_, err = os.ReadFile(configPath)
	if err != nil && !os.IsNotExist(err) {
		return nil, &AppError{"读取配置文件", configPath, err}
	}

	showProgress(text.GeneratingIds)
	config := NewStorageConfig()
	
	return config, nil
}

// 修改 waitExit 函数，正确初始化 reader
func waitExit() {
	reader := bufio.NewReader(os.Stdin)
	color.Cyan("\n" + texts[currentLanguage].PressEnterToExit)
	reader.ReadString('\n')
}

func main() {
	currentLanguage = detectLanguage()
	defer func() {
		if err := recover(); err != nil {
			color.Red(texts[currentLanguage].ErrorPrefix, err)
			waitExit()
		}
	}()

	// 添加权限检查
	isAdmin, err := checkAdminPrivileges()
	if err != nil {
			handleError("权限检查失败", err)
			waitExit()
			return
	}
	
	if !isAdmin {
		showPrivilegeError()
		waitExit()
		return
	}

	setupProgram()
	
	config, err := loadAndUpdateConfig()
	if err != nil {
		handleError("配置更新失败", err)
		return
	}
	
	if err := saveConfig(config); err != nil {
		handleError("保存配置失败", err)
		return
	}

	showSuccess()
	waitExit()
}

func setupProgram() {
	clearScreen()
	printCyberpunkBanner()
}

func handleError(msg string, err error) {
	if appErr, ok := err.(*AppError); ok {
		color.Red("%s: %v", msg, appErr)
	} else {
		color.Red("%s: %v", msg, err)
	}
}

func checkAdminPrivileges() (bool, error) {
	switch runtime.GOOS {
	case "windows":
		// Windows 管理员权限检查
		cmd := exec.Command("net", "session")
		err := cmd.Run()
		return err == nil, nil
		
	case "darwin", "linux":
		// Unix 系统检查 root 权限
		currentUser, err := user.Current()
		if err != nil {
			return false, fmt.Errorf("获取当前用户失败: %v", err)
		}
		return currentUser.Uid == "0", nil
		
	default:
		return false, fmt.Errorf("不支持的操作系统: %s", runtime.GOOS)
	}
}

func showPrivilegeError() {
	text := texts[currentLanguage]
	red := color.New(color.FgRed, color.Bold)
	yellow := color.New(color.FgYellow)
	
	red.Println(text.PrivilegeError)
	if runtime.GOOS == "windows" {
		yellow.Println(text.RunAsAdmin)
	} else {
		yellow.Println(text.RunWithSudo)
		yellow.Printf(text.SudoExample, os.Args[0])
	}
}

// 在文件开头添加新的类型和变量定义
type Language string

const (
    CN Language = "cn"
    EN Language = "en"
)

// TextResource 存储多语言文本
type TextResource struct {
    SuccessMessage      string
    RestartMessage      string
    ReadingConfig      string
    GeneratingIds      string
    PressEnterToExit   string
    ErrorPrefix        string
    PrivilegeError     string
    RunAsAdmin         string
    RunWithSudo        string
    SudoExample        string
}

var (
    currentLanguage = CN // 默认使用中文
    
    texts = map[Language]TextResource{
        CN: {
            SuccessMessage:    "[√] 配置文件已成功更新!",
            RestartMessage:    "[!] 请手动重启 Cursor 以使更改生效",
            ReadingConfig:     "正在读取配置文件...",
            GeneratingIds:     "正在生成新的标识符...",
            PressEnterToExit:  "按回车键退出程序...",
            ErrorPrefix:       "程序发生严重错误: %v",
            PrivilegeError:    "\n[!] 错误：需要管理员权限",
            RunAsAdmin:        "请右键点击程序，选择「以管理员身份运行」",
            RunWithSudo:       "请使用 sudo 命令运行此程序",
            SudoExample:       "示例: sudo %s",
        },
        EN: {
            SuccessMessage:    "[√] Configuration file updated successfully!",
            RestartMessage:    "[!] Please restart Cursor manually for changes to take effect",
            ReadingConfig:     "Reading configuration file...",
            GeneratingIds:     "Generating new identifiers...",
            PressEnterToExit:  "Press Enter to exit...",
            ErrorPrefix:       "Program encountered a serious error: %v",
            PrivilegeError:    "\n[!] Error: Administrator privileges required",
            RunAsAdmin:        "Please right-click and select 'Run as Administrator'",
            RunWithSudo:       "Please run this program with sudo",
            SudoExample:       "Example: sudo %s",
        },
    }
)

// 添加语言检测函数
func detectLanguage() Language {
    // 获取系统语言环境
    lang := os.Getenv("LANG")
    if lang == "" {
        lang = os.Getenv("LANGUAGE")
    }
    
    // 如果包含 zh 则使用中文，否则使用英文
    if strings.Contains(strings.ToLower(lang), "zh") {
        return CN
    }
    return EN
}
