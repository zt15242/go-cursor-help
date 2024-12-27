package ui

import (
	"fmt"
	"sync"
	"time"

	"github.com/fatih/color"
)

// SpinnerConfig defines spinner configuration
type SpinnerConfig struct {
	Frames []string
	Delay  time.Duration
}

// DefaultSpinnerConfig returns the default spinner configuration
func DefaultSpinnerConfig() *SpinnerConfig {
	return &SpinnerConfig{
		Frames: []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"},
		Delay:  100 * time.Millisecond,
	}
}

// Spinner represents a progress spinner
type Spinner struct {
	config  *SpinnerConfig
	message string
	current int
	active  bool
	stopCh  chan struct{}
	mu      sync.RWMutex
}

// NewSpinner creates a new spinner with the given configuration
func NewSpinner(config *SpinnerConfig) *Spinner {
	if config == nil {
		config = DefaultSpinnerConfig()
	}
	return &Spinner{
		config: config,
		stopCh: make(chan struct{}),
	}
}

// SetMessage sets the spinner message
func (s *Spinner) SetMessage(message string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.message = message
}

// Start starts the spinner animation
func (s *Spinner) Start() {
	s.mu.Lock()
	if s.active {
		s.mu.Unlock()
		return
	}
	s.active = true
	s.mu.Unlock()

	go s.run()
}

// Stop stops the spinner animation
func (s *Spinner) Stop() {
	s.mu.Lock()
	defer s.mu.Unlock()

	if !s.active {
		return
	}

	s.active = false
	close(s.stopCh)
	s.stopCh = make(chan struct{})
	fmt.Println()
}

// IsActive returns whether the spinner is currently active
func (s *Spinner) IsActive() bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.active
}

func (s *Spinner) run() {
	ticker := time.NewTicker(s.config.Delay)
	defer ticker.Stop()

	for {
		select {
		case <-s.stopCh:
			return
		case <-ticker.C:
			s.mu.RLock()
			if !s.active {
				s.mu.RUnlock()
				return
			}
			frame := s.config.Frames[s.current%len(s.config.Frames)]
			message := s.message
			s.current++
			s.mu.RUnlock()

			fmt.Printf("\r%s %s", color.CyanString(frame), message)
		}
	}
}
