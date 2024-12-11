package main

// 导入所需的包 / Import required packages
import (
	"bufio"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"runtime"
	"strings"
	"time"
	"github.com/fatih/color"
	"context"
	"errors"
	"runtime/debug"
)

// 语言类型和常量 / Language type and constants
type Language string

const (
	CN Language = "cn"
	EN Language = "en"

	// Version constant
	Version = "1.0.1"

	// 定义错误类型常量
	ErrPermission = "permission_error"
	ErrConfig     = "config_error"
	ErrProcess    = "process_error"
	ErrSystem     = "system_error"
)

// TextResource 存储多语言文本 / TextResource stores multilingual text
type TextResource struct {
	SuccessMessage   string
	RestartMessage   string
	ReadingConfig    string
	GeneratingIds    string
	PressEnterToExit string
	ErrorPrefix      string
	PrivilegeError   string
	RunAsAdmin       string
	RunWithSudo      string
	SudoExample      string
}

// StorageConfig 优化的存储配置结构 / StorageConfig optimized storage configuration struct
type StorageConfig struct {
	TelemetryMacMachineId string    `json:"telemetry.macMachineId"`
	TelemetryMachineId    string    `json:"telemetry.machineId"`
	TelemetryDevDeviceId  string    `json:"telemetry.devDeviceId"`
	LastModified          time.Time `json:"lastModified"`
	Version               string    `json:"version"`
}

// AppError 定义错误类型 / AppError defines error types
type AppError struct {
	Type    string
	Op      string
	Path    string
	Err     error
	Context map[string]interface{}
}

// ProgressSpinner 用于显示进度动画 / ProgressSpinner for showing progress animation
type ProgressSpinner struct {
	frames  []string
	current int
	message string
}

// SpinnerConfig 定义进度条配置
type SpinnerConfig struct {
	Frames []string
	Delay  time.Duration
}



// 全局变量 / Global variables
var (
	currentLanguage = CN // 默认为中文 / Default to Chinese

	texts = map[Language]TextResource{
		CN: {
			SuccessMessage:   "[√] 配置文件已成功更新!",
			RestartMessage:   "[!] 请手动重启 Cursor 以使更新生效",
			ReadingConfig:    "正在读取配置文件...",
			GeneratingIds:    "正在生成新的标识符...",
			PressEnterToExit: "按回车键退出程序...",
			ErrorPrefix:      "程序发生严重错误: %v",
			PrivilegeError:   "\n[!] 错误：需要管理员权限",
			RunAsAdmin:       "请右键点击程序，选择「以管理员身份运行」",
			RunWithSudo:      "请使用 sudo 命令运行此程序",
			SudoExample:      "示例: sudo %s",
		},
		EN: {
			SuccessMessage:   "[√] Configuration file updated successfully!",
			RestartMessage:   "[!] Please restart Cursor manually for changes to take effect",
			ReadingConfig:    "Reading configuration file...",
			GeneratingIds:    "Generating new identifiers...",
			PressEnterToExit: "Press Enter to exit...",
			ErrorPrefix:      "Program encountered a serious error: %v",
			PrivilegeError:   "\n[!] Error: Administrator privileges required",
			RunAsAdmin:       "Please right-click and select 'Run as Administrator'",
			RunWithSudo:      "Please run this program with sudo",
			SudoExample:      "Example: sudo %s",
		},
	}
)

// Error implementation for AppError
func (e *AppError) Error() string {
	if e.Context != nil {
		return fmt.Sprintf("[%s] %s: %v (context: %v)", e.Type, e.Op, e.Err, e.Context)
	}
	return fmt.Sprintf("[%s] %s: %v", e.Type, e.Op, e.Err)
}

// NewStorageConfig 创建新的实例 / Creates a new configuration instance
func NewStorageConfig() *StorageConfig {
	return &StorageConfig{
		TelemetryMacMachineId: generateMachineId(),
		TelemetryMachineId:    generateMachineId(),
		TelemetryDevDeviceId:  generateDevDeviceId(),
		LastModified:          time.Now(),
		Version:               Version,
	}
}

// 生成类似原始machineId的字符串(64位小十六进制) / Generate a string similar to the original machineId (64-bit lowercase hex)
func generateMachineId() string {
	data := make([]byte, 32)
	if _, err := rand.Read(data); err != nil {
		panic(fmt.Errorf("failed to generate random data: %v", err))
	}
	hash := sha256.Sum256(data)
	return hex.EncodeToString(hash[:])
}

// 生成类似原始devDeviceId的字符串(标准UUID格式) / Generate a string similar to the original devDeviceId (standard UUID format)
func generateDevDeviceId() string {
	uuid := make([]byte, 16)
	if _, err := rand.Read(uuid); err != nil {
		panic(fmt.Errorf("failed to generate UUID: %v", err))
	}

	uuid[6] = (uuid[6] & 0x0f) | 0x40 // Version 4
	uuid[8] = (uuid[8] & 0x3f) | 0x80 // RFC 4122 variant

	return fmt.Sprintf("%x-%x-%x-%x-%x",
		uuid[0:4],
		uuid[4:6],
		uuid[6:8],
		uuid[8:10],
		uuid[10:16])
}

// NewProgressSpinner creates a new progress spinner
func NewProgressSpinner(message string) *ProgressSpinner {
	return &ProgressSpinner{
		frames:  []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"},
		message: message,
	}
}

// Spin advances the spinner animation
func (s *ProgressSpinner) Spin() {
	frame := s.frames[s.current%len(s.frames)]
	s.current++
	fmt.Printf("\r%s %s", color.CyanString(frame), s.message)
}

// Stop ends the spinner animation
func (s *ProgressSpinner) Stop() {
	fmt.Println()
}

// Start starts the spinner animation
func (s *ProgressSpinner) Start() {
	s.current = 0
}

// File and system operations

func getConfigPath() (string, error) {
	var configDir string
	switch runtime.GOOS {
	case "windows":
		configDir = filepath.Join(os.Getenv("APPDATA"), "Cursor", "User", "globalStorage")
	case "darwin":
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		configDir = filepath.Join(homeDir, "Library", "Application Support", "Cursor", "User", "globalStorage")
	case "linux":
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		configDir = filepath.Join(homeDir, ".config", "Cursor", "User", "globalStorage")
	default:
		return "", fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}
	return filepath.Join(configDir, "storage.json"), nil
}

func safeWriteFile(path string, data []byte, perm os.FileMode) error {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return &AppError{
			Type: ErrSystem,
			Op:   "create directory",
			Path: dir,
			Err:  err,
		}
	}

	tmpPath := path + ".tmp"
	if err := os.WriteFile(tmpPath, data, perm); err != nil {
		return &AppError{
			Type: ErrSystem,
			Op:   "write temporary file",
			Path: tmpPath,
			Err:  err,
		}
	}

	if err := os.Rename(tmpPath, path); err != nil {
		os.Remove(tmpPath)
		return &AppError{
			Type: ErrSystem,
			Op:   "rename file",
			Path: path,
			Err:  err,
		}
	}

	return nil
}

func setFilePermissions(filePath string) error {
	return os.Chmod(filePath, 0444)
}

// Process management functions

type ProcessManager struct {
	config *SystemConfig
}

func (pm *ProcessManager) killCursorProcesses() error {
	ctx, cancel := context.WithTimeout(context.Background(), pm.config.Timeout)
	defer cancel()

	for attempt := 0; attempt < pm.config.RetryAttempts; attempt++ {
		if err := pm.killProcess(ctx); err != nil {
			time.Sleep(pm.config.RetryDelay)
			continue
		}
		return nil
	}
	
	return &AppError{
		Type: ErrProcess,
		Op:   "kill_processes",
		Err:  errors.New("failed to kill all Cursor processes after retries"),
	}
}

func (pm *ProcessManager) killProcess(ctx context.Context) error {
	if runtime.GOOS == "windows" {
		return pm.killWindowsProcess(ctx)
	}
	return pm.killUnixProcess(ctx)
}

func checkCursorRunning() bool {
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("tasklist", "/FI", "IMAGENAME eq Cursor.exe", "/NH")
	} else {
		cmd = exec.Command("pgrep", "-f", "Cursor")
	}

	output, _ := cmd.Output()
	return strings.Contains(string(output), "Cursor") || strings.Contains(string(output), "cursor")
}

// UI and display functions

func clearScreen() {
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("cmd", "/c", "cls")
	} else {
		cmd = exec.Command("clear")
	}
	cmd.Stdout = os.Stdout
	cmd.Run()
}

func showProgress(message string) {
	spinner := NewProgressSpinner(message)
	for i := 0; i < 15; i++ {
		spinner.Spin()
		time.Sleep(100 * time.Millisecond)
	}
	spinner.Stop()
}

func printCyberpunkBanner() {
	cyan := color.New(color.FgCyan, color.Bold)
	yellow := color.New(color.FgYellow, color.Bold)
	magenta := color.New(color.FgMagenta, color.Bold)
	green := color.New(color.FgGreen, color.Bold)

	banner := `
    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
   ██╔════╝██║   ██║██╔══██╗██╔════╝█╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
   ██║     ██║   ██║██╔══██╗╚════██ ██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚════╝ ╚═╝  ╚═╝
    `
	cyan.Println(banner)
	yellow.Println("\t\t>> Cursor ID Modifier v1.0 <<")
	magenta.Println("\t\t   [ By Pancake Fruit Rolled Shark Chili ]")

	langText := "当前语言/Language: "
	if currentLanguage == CN {
		langText += "简体中文"
	} else {
		langText += "English"
	}
	green.Printf("\n\t\t   %s\n\n", langText)
}

func showSuccess() {
	text := texts[currentLanguage]
	successColor := color.New(color.FgGreen, color.Bold)
	warningColor := color.New(color.FgYellow, color.Bold)

	successColor.Printf("\n%s\n", text.SuccessMessage)
	warningColor.Printf("%s\n", text.RestartMessage)
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

func showIdComparison(oldConfig *StorageConfig, newConfig *StorageConfig) {
	cyan := color.New(color.FgCyan)
	yellow := color.New(color.FgYellow)

	fmt.Println("\n=== ID Modification Comparison / ID 修改对比 ===")

	if oldConfig != nil {
		cyan.Println("\n[Original IDs / 原始 ID]")
		yellow.Printf("Machine ID: %s\n", oldConfig.TelemetryMachineId)
		yellow.Printf("Mac Machine ID: %s\n", oldConfig.TelemetryMacMachineId)
		yellow.Printf("Dev Device ID: %s\n", oldConfig.TelemetryDevDeviceId)
	}

	cyan.Println("\n[Newly Generated IDs / 新生成 ID]")
	yellow.Printf("Machine ID: %s\n", newConfig.TelemetryMachineId)
	yellow.Printf("Mac Machine ID: %s\n", newConfig.TelemetryMacMachineId)
	yellow.Printf("Dev Device ID: %s\n", newConfig.TelemetryDevDeviceId)
	fmt.Println()
}

// Configuration operations

func saveConfig(config *StorageConfig) error {
	configPath, err := getConfigPath()
	if err != nil {
		return err
	}

	content, err := json.MarshalIndent(config, "", "    ")
	if err != nil {
		return &AppError{
			Type: ErrSystem,
			Op:   "generate JSON",
			Path: "",
			Err:  err,
		}
	}

	if err := os.Chmod(configPath, 0666); err != nil && !os.IsNotExist(err) {
		return &AppError{
			Type: ErrSystem,
			Op:   "modify file permissions",
			Path: configPath,
			Err:  err,
		}
	}

	if err := safeWriteFile(configPath, content, 0666); err != nil {
		return err
	}

	return setFilePermissions(configPath)
}

func readExistingConfig() (*StorageConfig, error) {
	configPath, err := getConfigPath()
	if err != nil {
		return nil, err
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}

	var config StorageConfig
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	return &config, nil
}

func loadAndUpdateConfig(ui *UI) (*StorageConfig, error) {
	configPath, err := getConfigPath()
	if err != nil {
		return nil, err
	}

	text := texts[currentLanguage]
	ui.showProgress(text.ReadingConfig)

	_, err = os.ReadFile(configPath)
	if err != nil && !os.IsNotExist(err) {
		return nil, &AppError{
			Type: ErrSystem,
			Op:   "read config file",
			Path: configPath,
			Err:  err,
		}
	}

	showProgress(text.GeneratingIds)
	return NewStorageConfig(), nil
}

// System privilege functions

func checkAdminPrivileges() (bool, error) {
	switch runtime.GOOS {
	case "windows":
		cmd := exec.Command("whoami", "/groups")
		output, err := cmd.Output()
		if err != nil {
			return false, err
		}
		return strings.Contains(string(output), "S-1-16-12288") || 
			   strings.Contains(string(output), "S-1-5-32-544"), nil
		
	case "darwin", "linux":
		currentUser, err := user.Current()
		if err != nil {
			return false, fmt.Errorf("failed to get current user: %v", err)
		}
		return currentUser.Uid == "0", nil
		
	default:
		return false, fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}
}

// Utility functions

func detectLanguage() Language {
	lang := os.Getenv("LANG")
	if lang == "" {
		lang = os.Getenv("LANGUAGE")
	}

	if strings.Contains(strings.ToLower(lang), "zh") {
		return CN
	}
	return EN
}

func waitExit() {
	fmt.Println("\nPress Enter to exit... / 按回车键退出程序...")
	os.Stdout.Sync()
	bufio.NewReader(os.Stdin).ReadString('\n')
}

// 错误处理函数
func handleError(err error) {
	if err == nil {
		return
	}

	logger := log.New(os.Stderr, "", log.LstdFlags)
	
	switch e := err.(type) {
	case *AppError:
		logger.Printf("[ERROR] %v\n", e)
		if e.Type == ErrPermission {
			showPrivilegeError()
		}
	default:
		logger.Printf("[ERROR] Unexpected error: %v\n", err)
	}
}

// Main program entry

func main() {
	// 初始化错误恢复
	defer func() {
		if r := recover(); r != nil {
			log.Printf("Panic recovered: %v\n", r)
			debug.PrintStack()
			waitExit()
		}
	}()

	// 始化配置
	config := initConfig()
	
	// 初始化组件
	ui := NewUI(&config.UI)
	pm := &ProcessManager{
		config: &SystemConfig{
			RetryAttempts: 3,
			RetryDelay:    time.Second,
			Timeout:       30 * time.Second,
		},
	}
	
	// 权限检查
	os.Stdout.Sync()
	currentLanguage = detectLanguage()

	isAdmin, err := checkAdminPrivileges()
	if err != nil {
		handleError(err)
		waitExit()
		return
	}

	if !isAdmin && runtime.GOOS == "windows" {
		fmt.Println("Requesting administrator privileges... / 请求管理员权限...")
		if err := selfElevate(); err != nil {
			handleError(err)
			showPrivilegeError()
			waitExit()
			return
		}
		return
	} else if !isAdmin {
		showPrivilegeError()
		waitExit()
		return
	}

	if checkCursorRunning() {
		fmt.Println("\nDetected running Cursor instance(s). Closing... / 检测到正在运行的 Cursor 实例，正在关闭...")
		if err := pm.killCursorProcesses(); err != nil {
			fmt.Println("Warning: Could not close all Cursor instances. Please close them manually. / 警告：无法关闭所有 Cursor 实例，请手动关闭。")
			waitExit()
			return
		}

		time.Sleep(2 * time.Second)
		if checkCursorRunning() {
			fmt.Println("\nWarning: Cursor is still running. Please close it manually. / 警告：Cursor 仍在运行，请手动关闭。")
			waitExit()
			return
		}
	}

	clearScreen()
	printCyberpunkBanner()

	oldConfig, err := readExistingConfig()
	if err != nil {
		oldConfig = nil
	}

	storageConfig, err := loadAndUpdateConfig(ui)
	if err != nil {
		handleError(err)
		waitExit()
		return
	}

	showIdComparison(oldConfig, storageConfig)

	if err := saveConfig(storageConfig); err != nil {
		handleError(err)
		waitExit()
		return
	}

	showSuccess()
	fmt.Println("\nOperation completed! / 操作完成！")
	waitExit()
}

// 优化配置结构
type Config struct {
	Storage StorageConfig
	UI      UIConfig
	System  SystemConfig
}

type UIConfig struct {
	Language Language
	Theme    string
	Spinner  SpinnerConfig
}

type SystemConfig struct {
	RetryAttempts int
	RetryDelay    time.Duration
	Timeout       time.Duration
}

// 配置初始化函数
func initConfig() *Config {
	return &Config{
		Storage: StorageConfig{
			Version: Version,
		},
		UI: UIConfig{
			Language: detectLanguage(),
			Theme:    "default",
			Spinner: SpinnerConfig{
				Frames:  []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"},
				Delay:   100 * time.Millisecond,
			},
		},
		System: SystemConfig{
			RetryAttempts: 3,
			RetryDelay:    time.Second,
			Timeout:       30 * time.Second,
		},
	}
}

// UI 组件���化
type UI struct {
	config  *UIConfig
	spinner *ProgressSpinner
}

func NewUI(config *UIConfig) *UI {
	return &UI{
		config:  config,
		spinner: NewProgressSpinner(""),
	}
}

func (ui *UI) showProgress(message string) {
	ui.spinner.message = message
	ui.spinner.Start()
	defer ui.spinner.Stop()
	
	ticker := time.NewTicker(ui.config.Spinner.Delay)
	defer ticker.Stop()
	
	for i := 0; i < 15; i++ {
		<-ticker.C
		ui.spinner.Spin()
	}
}

func (pm *ProcessManager) killWindowsProcess(ctx context.Context) error {
	// 使用 taskkill 命令结束进程
	exec.CommandContext(ctx, "taskkill", "/IM", "Cursor.exe").Run()
	time.Sleep(pm.config.RetryDelay)
	exec.CommandContext(ctx, "taskkill", "/F", "/IM", "Cursor.exe").Run()
	return nil
}

func (pm *ProcessManager) killUnixProcess(ctx context.Context) error {
	exec.CommandContext(ctx, "pkill", "-f", "Cursor").Run()
	exec.CommandContext(ctx, "pkill", "-f", "cursor").Run()
	return nil
}

func selfElevate() error {
	switch runtime.GOOS {
	case "windows":
		// 使用 cmd 实现 Windows 下的提权
		verb := "runas"
		exe, _ := os.Executable()
		cwd, _ := os.Getwd()
		args := strings.Join(os.Args[1:], " ")
		
		cmd := exec.Command("cmd", "/C", "start", verb, exe, args)
		cmd.Dir = cwd
		return cmd.Run()
		
	case "darwin", "linux":
		// Unix 系统使用 sudo
		exe, err := os.Executable()
		if err != nil {
			return err
		}
		
		cmd := exec.Command("sudo", append([]string{exe}, os.Args[1:]...)...)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()
		
	default:
		return fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}
}


