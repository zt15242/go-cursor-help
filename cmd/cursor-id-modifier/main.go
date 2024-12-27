package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"runtime"
	"runtime/debug"
	"strings"
	"time"

	"github.com/dacrab/go-cursor-help/internal/config"
	"github.com/dacrab/go-cursor-help/internal/lang"
	"github.com/dacrab/go-cursor-help/internal/process"
	"github.com/dacrab/go-cursor-help/internal/ui"
	"github.com/dacrab/go-cursor-help/pkg/idgen"

	"github.com/sirupsen/logrus"
)

var (
	version     = "dev"
	setReadOnly = flag.Bool("r", false, "set storage.json to read-only mode")
	showVersion = flag.Bool("v", false, "show version information")
	log         = logrus.New()
)

func main() {
	// Initialize error recovery
	defer func() {
		if r := recover(); r != nil {
			log.Errorf("Panic recovered: %v\n", r)
			debug.PrintStack()
			waitExit()
		}
	}()

	// Parse flags
	flag.Parse()

	// Show version if requested
	if *showVersion {
		fmt.Printf("Cursor ID Modifier v%s\n", version)
		return
	}

	// Initialize logger
	log.SetFormatter(&logrus.TextFormatter{
		FullTimestamp: true,
	})

	// Get current user
	username := os.Getenv("SUDO_USER")
	if username == "" {
		user, err := user.Current()
		if err != nil {
			log.Fatal(err)
		}
		username = user.Username
	}

	// Initialize components
	display := ui.NewDisplay(nil)
	procManager := process.NewManager(process.DefaultConfig(), log)
	configManager, err := config.NewManager(username)
	if err != nil {
		log.Fatal(err)
	}
	generator := idgen.NewGenerator()

	// Check privileges
	isAdmin, err := checkAdminPrivileges()
	if err != nil {
		log.Error(err)
		waitExit()
		return
	}

	if !isAdmin {
		if runtime.GOOS == "windows" {
			message := "\nRequesting administrator privileges..."
			if lang.GetCurrentLanguage() == lang.CN {
				message = "\n请求管理员权限..."
			}
			fmt.Println(message)
			if err := selfElevate(); err != nil {
				log.Error(err)
				display.ShowPrivilegeError(
					lang.GetText().PrivilegeError,
					lang.GetText().RunAsAdmin,
					lang.GetText().RunWithSudo,
					lang.GetText().SudoExample,
				)
				waitExit()
				return
			}
			return
		}
		display.ShowPrivilegeError(
			lang.GetText().PrivilegeError,
			lang.GetText().RunAsAdmin,
			lang.GetText().RunWithSudo,
			lang.GetText().SudoExample,
		)
		waitExit()
		return
	}

	// Ensure Cursor is closed
	if err := ensureCursorClosed(display, procManager); err != nil {
		message := "\nError: Please close Cursor manually before running this program."
		if lang.GetCurrentLanguage() == lang.CN {
			message = "\n错误：请在运行此程序之前手动关闭 Cursor。"
		}
		display.ShowError(message)
		waitExit()
		return
	}

	// Kill any remaining Cursor processes
	if procManager.IsCursorRunning() {
		text := lang.GetText()
		display.ShowProcessStatus(text.ClosingProcesses)

		if err := procManager.KillCursorProcesses(); err != nil {
			fmt.Println()
			message := "Warning: Could not close all Cursor instances. Please close them manually."
			if lang.GetCurrentLanguage() == lang.CN {
				message = "警告：无法关闭所有 Cursor 实例，请手动关闭。"
			}
			display.ShowWarning(message)
			waitExit()
			return
		}

		if procManager.IsCursorRunning() {
			fmt.Println()
			message := "\nWarning: Cursor is still running. Please close it manually."
			if lang.GetCurrentLanguage() == lang.CN {
				message = "\n警告：Cursor 仍在运行，请手动关闭。"
			}
			display.ShowWarning(message)
			waitExit()
			return
		}

		display.ShowProcessStatus(text.ProcessesClosed)
		fmt.Println()
	}

	// Clear screen
	if err := display.ClearScreen(); err != nil {
		log.Warn("Failed to clear screen:", err)
	}

	// Show logo
	display.ShowLogo()

	// Read existing config
	text := lang.GetText()
	display.ShowProgress(text.ReadingConfig)

	oldConfig, err := configManager.ReadConfig()
	if err != nil {
		log.Warn("Failed to read existing config:", err)
		oldConfig = nil
	}

	// Generate new IDs
	display.ShowProgress(text.GeneratingIds)

	machineID, err := generator.GenerateMachineID()
	if err != nil {
		log.Fatal("Failed to generate machine ID:", err)
	}

	macMachineID, err := generator.GenerateMacMachineID()
	if err != nil {
		log.Fatal("Failed to generate MAC machine ID:", err)
	}

	deviceID, err := generator.GenerateDeviceID()
	if err != nil {
		log.Fatal("Failed to generate device ID:", err)
	}

	// Create new config
	newConfig := &config.StorageConfig{
		TelemetryMachineId:    machineID,
		TelemetryMacMachineId: macMachineID,
		TelemetryDevDeviceId:  deviceID,
	}

	if oldConfig != nil && oldConfig.TelemetrySqmId != "" {
		newConfig.TelemetrySqmId = oldConfig.TelemetrySqmId
	} else {
		sqmID, err := generator.GenerateMacMachineID()
		if err != nil {
			log.Fatal("Failed to generate SQM ID:", err)
		}
		newConfig.TelemetrySqmId = sqmID
	}

	// Save config
	if err := configManager.SaveConfig(newConfig, *setReadOnly); err != nil {
		log.Error(err)
		waitExit()
		return
	}

	// Show success
	display.ShowSuccess(text.SuccessMessage, text.RestartMessage)
	message := "\nOperation completed!"
	if lang.GetCurrentLanguage() == lang.CN {
		message = "\n操作完成！"
	}
	display.ShowInfo(message)

	if os.Getenv("AUTOMATED_MODE") != "1" {
		waitExit()
	}
}

func waitExit() {
	if os.Getenv("AUTOMATED_MODE") == "1" {
		return
	}

	fmt.Println(lang.GetText().PressEnterToExit)
	os.Stdout.Sync()
	bufio.NewReader(os.Stdin).ReadString('\n')
}

func ensureCursorClosed(display *ui.Display, procManager *process.Manager) error {
	maxAttempts := 3
	text := lang.GetText()

	display.ShowProcessStatus(text.CheckingProcesses)

	for attempt := 1; attempt <= maxAttempts; attempt++ {
		if !procManager.IsCursorRunning() {
			display.ShowProcessStatus(text.ProcessesClosed)
			fmt.Println()
			return nil
		}

		message := fmt.Sprintf("Please close Cursor before continuing. Attempt %d/%d\n%s",
			attempt, maxAttempts, text.PleaseWait)
		if lang.GetCurrentLanguage() == lang.CN {
			message = fmt.Sprintf("请在继续之前关闭 Cursor。尝试 %d/%d\n%s",
				attempt, maxAttempts, text.PleaseWait)
		}
		display.ShowProcessStatus(message)

		time.Sleep(5 * time.Second)
	}

	return fmt.Errorf("cursor is still running")
}

func checkAdminPrivileges() (bool, error) {
	switch runtime.GOOS {
	case "windows":
		cmd := exec.Command("net", "session")
		return cmd.Run() == nil, nil

	case "darwin", "linux":
		currentUser, err := user.Current()
		if err != nil {
			return false, fmt.Errorf("failed to get current user: %w", err)
		}
		return currentUser.Uid == "0", nil

	default:
		return false, fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}
}

func selfElevate() error {
	os.Setenv("AUTOMATED_MODE", "1")

	switch runtime.GOOS {
	case "windows":
		verb := "runas"
		exe, _ := os.Executable()
		cwd, _ := os.Getwd()
		args := strings.Join(os.Args[1:], " ")

		cmd := exec.Command("cmd", "/C", "start", verb, exe, args)
		cmd.Dir = cwd
		return cmd.Run()

	case "darwin", "linux":
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
