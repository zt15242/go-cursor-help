package main

// Core imports / 核心导入
import (
	"bufio"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"runtime"
	"runtime/debug"
	"strings"
	"time"

	"github.com/fatih/color"
)

// Version information
var version = "dev" // This will be overwritten by goreleaser

// Types and Constants / 类型和常量
type Language string

const (
	// Language options / 语言选项
	CN Language = "cn"
	EN Language = "en"

	// Error types / 错误类型
	ErrPermission = "permission_error"
	ErrConfig     = "config_error"
	ErrProcess    = "process_error"
	ErrSystem     = "system_error"
)

// Configuration Structures / 配置结构
type (
	// TextResource stores multilingual text / 存储多语言文本
	TextResource struct {
		SuccessMessage    string
		RestartMessage    string
		ReadingConfig     string
		GeneratingIds     string
		PressEnterToExit  string
		ErrorPrefix       string
		PrivilegeError    string
		RunAsAdmin        string
		RunWithSudo       string
		SudoExample       string
		ConfigLocation    string
		CheckingProcesses string
		ClosingProcesses  string
		ProcessesClosed   string
		PleaseWait        string
	}

	// StorageConfig optimized storage configuration / 优化的存储配置
	StorageConfig struct {
		TelemetryMacMachineId string `json:"telemetry.macMachineId"`
		TelemetryMachineId    string `json:"telemetry.machineId"`
		TelemetryDevDeviceId  string `json:"telemetry.devDeviceId"`
		TelemetrySqmId        string `json:"telemetry.sqmId"`
	}
	// AppError defines error types / 定义错误类型
	AppError struct {
		Type    string
		Op      string
		Path    string
		Err     error
		Context map[string]interface{}
	}

	// Config structures / 配置结构
	Config struct {
		Storage StorageConfig
		UI      UIConfig
		System  SystemConfig
	}

	UIConfig struct {
		Language Language
		Theme    string
		Spinner  SpinnerConfig
	}

	SystemConfig struct {
		RetryAttempts int
		RetryDelay    time.Duration
		Timeout       time.Duration
	}

	// SpinnerConfig defines spinner configuration / 定义进度条配置
	SpinnerConfig struct {
		Frames []string
		Delay  time.Duration
	}

	// ProgressSpinner for showing progress animation / 用于显示进度动画
	ProgressSpinner struct {
		frames  []string
		current int
		message string
	}
)

// Global Variables / 全局变量
var (
	currentLanguage = CN // Default to Chinese / 默认为中文

	texts = map[Language]TextResource{
		CN: {
			SuccessMessage:    "[√] 配置文件已成功更新！",
			RestartMessage:    "[!] 请手动重启 Cursor 以使更新生效",
			ReadingConfig:     "正在读取配置文件...",
			GeneratingIds:     "正在生成新的标识符...",
			PressEnterToExit:  "按回车键退出程序...",
			ErrorPrefix:       "程序发生严重错误: %v",
			PrivilegeError:    "\n[!] 错误：需要管理员权限",
			RunAsAdmin:        "请右键点击程序，选择「以管理员身份运行」",
			RunWithSudo:       "请使用 sudo 命令运行此程序",
			SudoExample:       "示例: sudo %s",
			ConfigLocation:    "配置文件位置:",
			CheckingProcesses: "正在检查运行中的 Cursor 实例...",
			ClosingProcesses:  "正在关闭 Cursor 实例...",
			ProcessesClosed:   "所有 Cursor 实例已关闭",
			PleaseWait:        "请稍候...",
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
			ConfigLocation:    "Config file location:",
			CheckingProcesses: "Checking for running Cursor instances...",
			ClosingProcesses:  "Closing Cursor instances...",
			ProcessesClosed:   "All Cursor instances have been closed",
			PleaseWait:        "Please wait...",
		},
	}
)

// Error Implementation / 错误实现
func (e *AppError) Error() string {
	if e.Context != nil {
		return fmt.Sprintf("[%s] %s: %v (context: %v)", e.Type, e.Op, e.Err, e.Context)
	}
	return fmt.Sprintf("[%s] %s: %v", e.Type, e.Op, e.Err)
}

// Configuration Functions / 配置函数
func NewStorageConfig(oldConfig *StorageConfig) *StorageConfig { // Modified to take old config
	newConfig := &StorageConfig{
		TelemetryMacMachineId: generateMachineId(),
		TelemetryMachineId:    generateMachineId(),
		TelemetryDevDeviceId:  generateDevDeviceId(),
	}

	if oldConfig != nil {
		newConfig.TelemetrySqmId = oldConfig.TelemetrySqmId
	} else {
		newConfig.TelemetrySqmId = generateMachineId()
	}

	if newConfig.TelemetrySqmId == "" {
		newConfig.TelemetrySqmId = generateMachineId()
	}

	return newConfig
}

// ID Generation Functions / ID生成函数
func generateMachineId() string {
	data := make([]byte, 32)
	if _, err := rand.Read(data); err != nil {
		panic(fmt.Errorf("failed to generate random data: %v", err))
	}
	hash := sha256.Sum256(data)
	return hex.EncodeToString(hash[:])
}

func generateDevDeviceId() string {
	uuid := make([]byte, 16)
	if _, err := rand.Read(uuid); err != nil {
		panic(fmt.Errorf("failed to generate UUID: %v", err))
	}
	uuid[6] = (uuid[6] & 0x0f) | 0x40 // Version 4
	uuid[8] = (uuid[8] & 0x3f) | 0x80 // RFC 4122 variant
	return fmt.Sprintf("%x-%x-%x-%x-%x",
		uuid[0:4], uuid[4:6], uuid[6:8], uuid[8:10], uuid[10:16])
}

// File Operations / 文件操作
func getConfigPath(username string) (string, error) {
	var configDir string
	switch runtime.GOOS {
	case "windows":
		configDir = filepath.Join(os.Getenv("APPDATA"), "Cursor", "User", "globalStorage")
	case "darwin":
		configDir = filepath.Join("/Users", username, "Library", "Application Support", "Cursor", "User", "globalStorage")
	case "linux":
		configDir = filepath.Join("/home", username, ".config", "Cursor", "User", "globalStorage")
	default:
		return "", fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}
	return filepath.Join(configDir, "storage.json"), nil
}

func saveConfig(config *StorageConfig, username string) error { // Modified to take username
	configPath, err := getConfigPath(username)
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

	// Create parent directories with proper permissions
	dir := filepath.Dir(configPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return &AppError{
			Type: ErrSystem,
			Op:   "create directory",
			Path: dir,
			Err:  err,
		}
	}

	// First ensure we can write to the file
	if err := os.Chmod(configPath, 0666); err != nil && !os.IsNotExist(err) {
		return &AppError{
			Type: ErrSystem,
			Op:   "modify file permissions",
			Path: configPath,
			Err:  err,
		}
	}

	// Write to temporary file first
	tmpPath := configPath + ".tmp"
	if err := os.WriteFile(tmpPath, content, 0666); err != nil {
		return &AppError{
			Type: ErrSystem,
			Op:   "write temporary file",
			Path: tmpPath,
			Err:  err,
		}
	}

	// Ensure proper permissions on temporary file
	if err := os.Chmod(tmpPath, 0444); err != nil {
		os.Remove(tmpPath)
		return &AppError{
			Type: ErrSystem,
			Op:   "set temporary file permissions",
			Path: tmpPath,
			Err:  err,
		}
	}

	// Atomic rename
	if err := os.Rename(tmpPath, configPath); err != nil {
		os.Remove(tmpPath)
		return &AppError{
			Type: ErrSystem,
			Op:   "rename file",
			Path: configPath,
			Err:  err,
		}
	}

	// Sync the directory to ensure changes are written to disk
	if dir, err := os.Open(filepath.Dir(configPath)); err == nil {
		dir.Sync()
		dir.Close()
	}

	return nil
}

func readExistingConfig(username string) (*StorageConfig, error) { // Modified to take username
	configPath, err := getConfigPath(username)
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

// Process Management / 进程管理
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

func (pm *ProcessManager) killWindowsProcess(ctx context.Context) error {
	exec.CommandContext(ctx, "taskkill", "/IM", "Cursor.exe").Run()
	time.Sleep(pm.config.RetryDelay)
	exec.CommandContext(ctx, "taskkill", "/F", "/IM", "Cursor.exe").Run()
	return nil
}

func (pm *ProcessManager) killUnixProcess(ctx context.Context) error {
	// Search for the process by it's executable name (AppRun) in ps output
	cmd := exec.CommandContext(ctx, "ps", "aux")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to execute ps command: %w", err)
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.Contains(line, "AppRun") {
			parts := strings.Fields(line)
			if len(parts) > 1 {
				pid := parts[1]
				if err := pm.forceKillProcess(ctx, pid); err != nil {
					return err
				}
			}
		}

		// handle lowercase
		if strings.Contains(line, "apprun") {
			parts := strings.Fields(line)
			if len(parts) > 1 {
				pid := parts[1]
				if err := pm.forceKillProcess(ctx, pid); err != nil {
					return err
				}
			}
		}
	}

	return nil
}

// helper function to kill process by pid
func (pm *ProcessManager) forceKillProcess(ctx context.Context, pid string) error {
	// First try graceful termination
	if err := exec.CommandContext(ctx, "kill", pid).Run(); err == nil {
		// Wait for processes to terminate gracefully
		time.Sleep(2 * time.Second)
	}

	// Force kill if still running
	if err := exec.CommandContext(ctx, "kill", "-9", pid).Run(); err != nil {
		return fmt.Errorf("failed to force kill process %s: %w", pid, err)
	}

	return nil
}

func checkCursorRunning() bool {
	cmd := exec.Command("ps", "aux")
	output, err := cmd.Output()
	if err != nil {
		return false
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.Contains(line, "AppRun") || strings.Contains(line, "apprun") {
			return true
		}
	}

	return false
}

// UI Components / UI组件
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

// Display Functions / 显示函数
func showSuccess() {
	text := texts[currentLanguage]
	successColor := color.New(color.FgGreen, color.Bold)
	warningColor := color.New(color.FgYellow, color.Bold)
	pathColor := color.New(color.FgCyan)

	// Clear any previous output
	fmt.Println()

	if currentLanguage == EN {
		// English messages with extra spacing
		successColor.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		successColor.Printf("%s\n", text.SuccessMessage)
		fmt.Println()
		warningColor.Printf("%s\n", text.RestartMessage)
		successColor.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	} else {
		// Chinese messages with extra spacing
		successColor.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		successColor.Printf("%s\n", text.SuccessMessage)
		fmt.Println()
		warningColor.Printf("%s\n", text.RestartMessage)
		successColor.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	}

	// Add spacing before config location
	fmt.Println()

	username := os.Getenv("SUDO_USER")
	if username == "" {
		user, err := user.Current()
		if err != nil {
			panic(err)
		}
		username = user.Username
	}
	if configPath, err := getConfigPath(username); err == nil {
		pathColor.Printf("%s\n%s\n", text.ConfigLocation, configPath)
	}
}

func showPrivilegeError() {
	text := texts[currentLanguage]
	red := color.New(color.FgRed, color.Bold)
	yellow := color.New(color.FgYellow)

	if currentLanguage == EN {
		red.Println(text.PrivilegeError)
		if runtime.GOOS == "windows" {
			yellow.Println(text.RunAsAdmin)
		} else {
			yellow.Printf("%s\n%s\n", text.RunWithSudo, fmt.Sprintf(text.SudoExample, os.Args[0]))
		}
	} else {
		red.Printf("\n%s\n", text.PrivilegeError)
		if runtime.GOOS == "windows" {
			yellow.Printf("%s\n", text.RunAsAdmin)
		} else {
			yellow.Printf("%s\n%s\n", text.RunWithSudo, fmt.Sprintf(text.SudoExample, os.Args[0]))
		}
	}
}

// System Functions / 系统函数
func checkAdminPrivileges() (bool, error) {
	switch runtime.GOOS {
	case "windows":
		// 使用更可靠的方法检查Windows管理员权限
		cmd := exec.Command("net", "session")
		err := cmd.Run()
		if err == nil {
			return true, nil
		}
		// 如果命令执行失败，说明没有管理员权限
		return false, nil

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

func detectLanguage() Language {
	// Check common environment variables
	for _, envVar := range []string{"LANG", "LANGUAGE", "LC_ALL"} {
		if lang := os.Getenv(envVar); lang != "" {
			if strings.Contains(strings.ToLower(lang), "zh") {
				return CN
			}
		}
	}

	// Windows-specific language check
	if runtime.GOOS == "windows" {
		cmd := exec.Command("powershell", "-Command",
			"[System.Globalization.CultureInfo]::CurrentUICulture.Name")
		output, err := cmd.Output()
		if err == nil {
			lang := strings.ToLower(strings.TrimSpace(string(output)))
			if strings.HasPrefix(lang, "zh") {
				return CN
			}
		}

		// Check Windows locale
		cmd = exec.Command("wmic", "os", "get", "locale")
		output, err = cmd.Output()
		if err == nil && strings.Contains(string(output), "2052") {
			return CN
		}
	}

	// Check Unix locale
	if runtime.GOOS != "windows" {
		cmd := exec.Command("locale")
		output, err := cmd.Output()
		if err == nil && strings.Contains(strings.ToLower(string(output)), "zh_cn") {
			return CN
		}
	}

	return EN
}

func selfElevate() error {
	switch runtime.GOOS {
	case "windows":
		// Set automated mode for the elevated process
		os.Setenv("AUTOMATED_MODE", "1")

		verb := "runas"
		exe, _ := os.Executable()
		cwd, _ := os.Getwd()
		args := strings.Join(os.Args[1:], " ")

		cmd := exec.Command("cmd", "/C", "start", verb, exe, args)
		cmd.Dir = cwd
		return cmd.Run()

	case "darwin", "linux":
		// Set automated mode for the elevated process
		os.Setenv("AUTOMATED_MODE", "1")

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

// Utility Functions / 实用函数
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

func waitExit() {
	// Skip waiting in automated mode
	if os.Getenv("AUTOMATED_MODE") == "1" {
		return
	}

	if currentLanguage == EN {
		fmt.Println("\nPress Enter to exit...")
	} else {
		fmt.Println("\n按回车键退出程序...")
	}
	os.Stdout.Sync()
	bufio.NewReader(os.Stdin).ReadString('\n')
}

// Add this new function near the other process management functions
func ensureCursorClosed() error {
	maxAttempts := 3
	text := texts[currentLanguage]

	showProcessStatus(text.CheckingProcesses)

	for attempt := 1; attempt <= maxAttempts; attempt++ {
		if !checkCursorRunning() {
			showProcessStatus(text.ProcessesClosed)
			fmt.Println() // New line after status
			return nil
		}

		if currentLanguage == EN {
			showProcessStatus(fmt.Sprintf("Please close Cursor before continuing. Attempt %d/%d\n%s",
				attempt, maxAttempts, text.PleaseWait))
		} else {
			showProcessStatus(fmt.Sprintf("请在继续之前关闭 Cursor。尝试 %d/%d\n%s",
				attempt, maxAttempts, text.PleaseWait))
		}

		time.Sleep(5 * time.Second)
	}

	return errors.New("cursor is still running")
}

func main() {
	// Initialize error recovery
	defer func() {
		if r := recover(); r != nil {
			log.Printf("Panic recovered: %v\n", r)
			debug.PrintStack()
			waitExit()
		}
	}()

	var username string
	if username = os.Getenv("SUDO_USER"); username == "" {
		user, err := user.Current()
		if err != nil {
			panic(err)
		}
		username = user.Username
	}
	log.Println("Current user: ", username)

	// Initialize configuration
	ui := NewUI(&UIConfig{
		Language: detectLanguage(),
		Theme:    "default",
		Spinner: SpinnerConfig{
			Frames: []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"},
			Delay:  100 * time.Millisecond,
		},
	})

	// Check privileges
	os.Stdout.Sync()
	currentLanguage = detectLanguage()
	log.Println("Current language: ", currentLanguage)
	isAdmin, err := checkAdminPrivileges()
	if err != nil {
		handleError(err)
		waitExit()
		return
	}

	if !isAdmin && runtime.GOOS == "windows" {
		if currentLanguage == EN {
			fmt.Println("\nRequesting administrator privileges...")
		} else {
			fmt.Println("\n请求管理员权限...")
		}
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

	// Ensure all Cursor instances are closed
	if err := ensureCursorClosed(); err != nil {
		if currentLanguage == EN {
			fmt.Println("\nError: Please close Cursor manually before running this program.")
		} else {
			fmt.Println("\n错误：请在运行此程序之前手动关闭 Cursor。")
		}
		waitExit()
		return
	}

	// Process management
	pm := &ProcessManager{
		config: &SystemConfig{
			RetryAttempts: 3,
			RetryDelay:    time.Second,
			Timeout:       30 * time.Second,
		},
	}
	if checkCursorRunning() {
		text := texts[currentLanguage]
		showProcessStatus(text.ClosingProcesses)

		if err := pm.killCursorProcesses(); err != nil {
			fmt.Println() // New line after status
			if currentLanguage == EN {
				fmt.Println("Warning: Could not close all Cursor instances. Please close them manually.")
			} else {
				fmt.Println("警告：无法关闭所有 Cursor 实例，请手动关闭。")
			}
			waitExit()
			return
		}

		time.Sleep(2 * time.Second)
		if checkCursorRunning() {
			fmt.Println() // New line after status
			if currentLanguage == EN {
				fmt.Println("\nWarning: Cursor is still running. Please close it manually.")
			} else {
				fmt.Println("\n警告：Cursor 仍在运行，请手动关闭。")
			}
			waitExit()
			return
		}

		showProcessStatus(text.ProcessesClosed)
		fmt.Println() // New line after status
	}

	// Clear screen and show banner
	clearScreen()
	printCyberpunkBanner()

	// Read and update configuration
	oldConfig, err := readExistingConfig(username) // add username parameter
	if err != nil {
		oldConfig = nil
	}

	storageConfig, err := loadAndUpdateConfig(ui, username) // add username parameter
	if err != nil {
		handleError(err)
		waitExit()
		return
	}

	// Show changes and save
	showIdComparison(oldConfig, storageConfig)

	if err := saveConfig(storageConfig, username); err != nil { // add username parameter
		handleError(err)
		waitExit()
		return
	}

	// Show success and exit
	showSuccess()
	if currentLanguage == EN {
		fmt.Println("\nOperation completed!")
	} else {
		fmt.Println("\n操作完成！")
	}

	// Check if running in automated mode
	if os.Getenv("AUTOMATED_MODE") == "1" {
		return
	}

	waitExit()
}

// Progress spinner functions / 进度条函数
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

func (s *ProgressSpinner) Start() {
	s.current = 0
}

// Display utility functions / 显示工具函数
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

func printCyberpunkBanner() {
	cyan := color.New(color.FgCyan, color.Bold)
	yellow := color.New(color.FgYellow, color.Bold)
	magenta := color.New(color.FgMagenta, color.Bold)
	green := color.New(color.FgGreen, color.Bold)

	banner := `
    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║█████╔╝
   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
    `
	cyan.Println(banner)
	yellow.Printf("\t\t>> Cursor ID Modifier %s <<\n", version)
	magenta.Println("\t\t   [ By Pancake Fruit Rolled Shark Chili ]")

	langText := "当前语言/Language: "
	if currentLanguage == CN {
		langText += "简体中文"
	} else {
		langText += "English"
	}
	green.Printf("\n\t\t   %s\n\n", langText)
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
	yellow.Printf("SQM ID: %s\n", newConfig.TelemetrySqmId)
	fmt.Println()
}

// Configuration functions / 配置函数
func loadAndUpdateConfig(ui *UI, username string) (*StorageConfig, error) { // add username parameter
	configPath, err := getConfigPath(username) // add username parameter
	if err != nil {
		return nil, err
	}

	text := texts[currentLanguage]
	ui.showProgress(text.ReadingConfig)

	oldConfig, err := readExistingConfig(username) // add username parameter
	if err != nil && !os.IsNotExist(err) {
		return nil, &AppError{
			Type: ErrSystem,
			Op:   "read config file",
			Path: configPath,
			Err:  err,
		}
	}

	ui.showProgress(text.GeneratingIds)
	return NewStorageConfig(oldConfig), nil
}

// Add a new function to show process status
func showProcessStatus(message string) {
	cyan := color.New(color.FgCyan)
	fmt.Printf("\r%s", strings.Repeat(" ", 80)) // Clear line
	fmt.Printf("\r%s", cyan.Sprint("⚡ "+message))
}
