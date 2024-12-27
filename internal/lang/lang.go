package lang

import (
	"os"
	"os/exec"
	"strings"
	"sync"
)

// Language represents a supported language
type Language string

const (
	// CN represents Chinese language
	CN Language = "cn"
	// EN represents English language
	EN Language = "en"
)

// TextResource contains all translatable text resources
type TextResource struct {
	SuccessMessage     string
	RestartMessage     string
	ReadingConfig      string
	GeneratingIds      string
	PressEnterToExit   string
	ErrorPrefix        string
	PrivilegeError     string
	RunAsAdmin         string
	RunWithSudo        string
	SudoExample        string
	ConfigLocation     string
	CheckingProcesses  string
	ClosingProcesses   string
	ProcessesClosed    string
	PleaseWait         string
	SetReadOnlyMessage string
}

var (
	currentLanguage     Language
	currentLanguageOnce sync.Once
	languageMutex       sync.RWMutex
)

// GetCurrentLanguage returns the current language, detecting it if not already set
func GetCurrentLanguage() Language {
	currentLanguageOnce.Do(func() {
		currentLanguage = detectLanguage()
	})

	languageMutex.RLock()
	defer languageMutex.RUnlock()
	return currentLanguage
}

// SetLanguage sets the current language
func SetLanguage(lang Language) {
	languageMutex.Lock()
	defer languageMutex.Unlock()
	currentLanguage = lang
}

// GetText returns the TextResource for the current language
func GetText() TextResource {
	return texts[GetCurrentLanguage()]
}

// detectLanguage detects the system language
func detectLanguage() Language {
	// Check environment variables
	for _, envVar := range []string{"LANG", "LANGUAGE", "LC_ALL"} {
		if lang := os.Getenv(envVar); lang != "" && strings.Contains(strings.ToLower(lang), "zh") {
			return CN
		}
	}

	// Check Windows language settings
	if isWindows() {
		if isWindowsChineseLocale() {
			return CN
		}
	} else {
		// Check Unix locale
		if isUnixChineseLocale() {
			return CN
		}
	}

	return EN
}

func isWindows() bool {
	return os.Getenv("OS") == "Windows_NT"
}

func isWindowsChineseLocale() bool {
	// Check Windows UI culture
	cmd := exec.Command("powershell", "-Command",
		"[System.Globalization.CultureInfo]::CurrentUICulture.Name")
	output, err := cmd.Output()
	if err == nil && strings.HasPrefix(strings.ToLower(strings.TrimSpace(string(output))), "zh") {
		return true
	}

	// Check Windows locale
	cmd = exec.Command("wmic", "os", "get", "locale")
	output, err = cmd.Output()
	return err == nil && strings.Contains(string(output), "2052")
}

func isUnixChineseLocale() bool {
	cmd := exec.Command("locale")
	output, err := cmd.Output()
	return err == nil && strings.Contains(strings.ToLower(string(output)), "zh_cn")
}

// texts contains all translations
var texts = map[Language]TextResource{
	CN: {
		SuccessMessage:     "[√] 配置文件已成功更新！",
		RestartMessage:     "[!] 请手动重启 Cursor 以使更新生效",
		ReadingConfig:      "正在读取配置文件...",
		GeneratingIds:      "正在生成新的标识符...",
		PressEnterToExit:   "按回车键退出程序...",
		ErrorPrefix:        "程序发生严重错误: %v",
		PrivilegeError:     "\n[!] 错误：需要管理员权限",
		RunAsAdmin:         "请右键点击程序，选择「以管理员身份运行」",
		RunWithSudo:        "请使用 sudo 命令运行此程序",
		SudoExample:        "示例: sudo %s",
		ConfigLocation:     "配置文件位置:",
		CheckingProcesses:  "正在检查运行中的 Cursor 实例...",
		ClosingProcesses:   "正在关闭 Cursor 实例...",
		ProcessesClosed:    "所有 Cursor 实例已关闭",
		PleaseWait:         "请稍候...",
		SetReadOnlyMessage: "设置 storage.json 为只读模式, 这将导致 workspace 记录信息丢失等问题",
	},
	EN: {
		SuccessMessage:     "[√] Configuration file updated successfully!",
		RestartMessage:     "[!] Please restart Cursor manually for changes to take effect",
		ReadingConfig:      "Reading configuration file...",
		GeneratingIds:      "Generating new identifiers...",
		PressEnterToExit:   "Press Enter to exit...",
		ErrorPrefix:        "Program encountered a serious error: %v",
		PrivilegeError:     "\n[!] Error: Administrator privileges required",
		RunAsAdmin:         "Please right-click and select 'Run as Administrator'",
		RunWithSudo:        "Please run this program with sudo",
		SudoExample:        "Example: sudo %s",
		ConfigLocation:     "Config file location:",
		CheckingProcesses:  "Checking for running Cursor instances...",
		ClosingProcesses:   "Closing Cursor instances...",
		ProcessesClosed:    "All Cursor instances have been closed",
		PleaseWait:         "Please wait...",
		SetReadOnlyMessage: "Set storage.json to read-only mode, which will cause issues such as lost workspace records",
	},
}
