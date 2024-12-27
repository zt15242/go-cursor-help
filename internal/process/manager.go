package process

import (
	"context"
	"fmt"
	"os/exec"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
)

// Config holds process manager configuration
type Config struct {
	RetryAttempts int
	RetryDelay    time.Duration
	Timeout       time.Duration
}

// DefaultConfig returns the default configuration
func DefaultConfig() *Config {
	return &Config{
		RetryAttempts: 3,
		RetryDelay:    time.Second,
		Timeout:       30 * time.Second,
	}
}

// Manager handles process-related operations
type Manager struct {
	config *Config
	log    *logrus.Logger
	mu     sync.Mutex
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

// KillCursorProcesses attempts to kill all Cursor processes
func (m *Manager) KillCursorProcesses() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	ctx, cancel := context.WithTimeout(context.Background(), m.config.Timeout)
	defer cancel()

	for attempt := 0; attempt < m.config.RetryAttempts; attempt++ {
		m.log.Debugf("Attempt %d/%d to kill Cursor processes", attempt+1, m.config.RetryAttempts)

		if err := m.killProcess(ctx); err != nil {
			m.log.Warnf("Failed to kill processes on attempt %d: %v", attempt+1, err)
			time.Sleep(m.config.RetryDelay)
			continue
		}
		return nil
	}

	return fmt.Errorf("failed to kill all Cursor processes after %d attempts", m.config.RetryAttempts)
}

// IsCursorRunning checks if any Cursor process is running
func (m *Manager) IsCursorRunning() bool {
	m.mu.Lock()
	defer m.mu.Unlock()

	processes, err := m.listCursorProcesses()
	if err != nil {
		m.log.Warnf("Failed to list Cursor processes: %v", err)
		return false
	}

	return len(processes) > 0
}

func (m *Manager) killProcess(ctx context.Context) error {
	if runtime.GOOS == "windows" {
		return m.killWindowsProcess(ctx)
	}
	return m.killUnixProcess(ctx)
}

func (m *Manager) killWindowsProcess(ctx context.Context) error {
	// First try graceful termination
	if err := exec.CommandContext(ctx, "taskkill", "/IM", "Cursor.exe").Run(); err != nil {
		m.log.Debugf("Graceful termination failed: %v", err)
	}

	time.Sleep(m.config.RetryDelay)

	// Force kill if still running
	if err := exec.CommandContext(ctx, "taskkill", "/F", "/IM", "Cursor.exe").Run(); err != nil {
		return fmt.Errorf("failed to force kill Cursor process: %w", err)
	}

	return nil
}

func (m *Manager) killUnixProcess(ctx context.Context) error {
	processes, err := m.listCursorProcesses()
	if err != nil {
		return fmt.Errorf("failed to list processes: %w", err)
	}

	for _, pid := range processes {
		if err := m.forceKillProcess(ctx, pid); err != nil {
			m.log.Warnf("Failed to kill process %s: %v", pid, err)
			continue
		}
	}

	return nil
}

func (m *Manager) forceKillProcess(ctx context.Context, pid string) error {
	// Try graceful termination first
	if err := exec.CommandContext(ctx, "kill", pid).Run(); err == nil {
		m.log.Debugf("Process %s terminated gracefully", pid)
		time.Sleep(2 * time.Second)
		return nil
	}

	// Force kill if still running
	if err := exec.CommandContext(ctx, "kill", "-9", pid).Run(); err != nil {
		return fmt.Errorf("failed to force kill process %s: %w", pid, err)
	}

	m.log.Debugf("Process %s force killed", pid)
	return nil
}

func (m *Manager) listCursorProcesses() ([]string, error) {
	cmd := exec.Command("ps", "aux")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to execute ps command: %w", err)
	}

	var pids []string
	for _, line := range strings.Split(string(output), "\n") {
		if strings.Contains(strings.ToLower(line), "apprun") {
			fields := strings.Fields(line)
			if len(fields) > 1 {
				pids = append(pids, fields[1])
			}
		}
	}

	return pids, nil
}
