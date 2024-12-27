package process

import (
	"fmt"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
)

// Config holds process manager configuration
type Config struct {
	MaxAttempts     int
	RetryDelay      time.Duration
	ProcessPatterns []string
}

// DefaultConfig returns the default configuration
func DefaultConfig() *Config {
	return &Config{
		MaxAttempts: 3,
		RetryDelay:  time.Second,
		ProcessPatterns: []string{
			"Cursor.exe",         // Windows
			"Cursor",             // Linux/macOS binary
			"cursor",             // Linux/macOS process
			"cursor-helper",      // Helper process
			"cursor-id-modifier", // Our tool
		},
	}
}

// Manager handles process-related operations
type Manager struct {
	config *Config
	log    *logrus.Logger
}

// NewManager creates a new process manager
func NewManager(config *Config, log *logrus.Logger) *Manager {
	if config == nil {
		config = DefaultConfig()
	}
	if log == nil {
		log = logrus.New()
	}
	return &Manager{
		config: config,
		log:    log,
	}
}

// IsCursorRunning checks if any Cursor process is running
func (m *Manager) IsCursorRunning() bool {
	processes, err := m.getCursorProcesses()
	if err != nil {
		m.log.Warn("Failed to get Cursor processes:", err)
		return false
	}
	return len(processes) > 0
}

// KillCursorProcesses attempts to kill all Cursor processes
func (m *Manager) KillCursorProcesses() error {
	for attempt := 1; attempt <= m.config.MaxAttempts; attempt++ {
		processes, err := m.getCursorProcesses()
		if err != nil {
			return fmt.Errorf("failed to get processes: %w", err)
		}

		if len(processes) == 0 {
			return nil
		}

		for _, proc := range processes {
			if err := m.killProcess(proc); err != nil {
				m.log.Warnf("Failed to kill process %s: %v", proc, err)
			}
		}

		time.Sleep(m.config.RetryDelay)
	}

	if m.IsCursorRunning() {
		return fmt.Errorf("failed to kill all Cursor processes after %d attempts", m.config.MaxAttempts)
	}

	return nil
}

func (m *Manager) getCursorProcesses() ([]string, error) {
	var cmd *exec.Cmd
	var processes []string

	switch runtime.GOOS {
	case "windows":
		cmd = exec.Command("tasklist", "/FO", "CSV", "/NH")
	case "darwin":
		cmd = exec.Command("ps", "-ax")
	case "linux":
		cmd = exec.Command("ps", "-A")
	default:
		return nil, fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}

	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to execute command: %w", err)
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		for _, pattern := range m.config.ProcessPatterns {
			if strings.Contains(strings.ToLower(line), strings.ToLower(pattern)) {
				// Extract PID based on OS
				pid := m.extractPID(line)
				if pid != "" {
					processes = append(processes, pid)
				}
			}
		}
	}

	return processes, nil
}

func (m *Manager) extractPID(line string) string {
	switch runtime.GOOS {
	case "windows":
		// Windows CSV format: "ImageName","PID",...
		parts := strings.Split(line, ",")
		if len(parts) >= 2 {
			return strings.Trim(parts[1], "\"")
		}
	case "darwin", "linux":
		// Unix format: PID TTY TIME CMD
		parts := strings.Fields(line)
		if len(parts) >= 1 {
			return parts[0]
		}
	}
	return ""
}

func (m *Manager) killProcess(pid string) error {
	var cmd *exec.Cmd

	switch runtime.GOOS {
	case "windows":
		cmd = exec.Command("taskkill", "/F", "/PID", pid)
	case "darwin", "linux":
		cmd = exec.Command("kill", "-9", pid)
	default:
		return fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}

	return cmd.Run()
}
