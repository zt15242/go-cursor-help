package ui

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"github.com/fatih/color"
)

// Display handles UI display operations
type Display struct {
	spinner *Spinner
}

// NewDisplay creates a new display handler
func NewDisplay(spinner *Spinner) *Display {
	if spinner == nil {
		spinner = NewSpinner(nil)
	}
	return &Display{
		spinner: spinner,
	}
}

// ShowProgress shows a progress message with spinner
func (d *Display) ShowProgress(message string) {
	d.spinner.SetMessage(message)
	d.spinner.Start()
}

// StopProgress stops the progress spinner
func (d *Display) StopProgress() {
	d.spinner.Stop()
}

// ClearScreen clears the terminal screen
func (d *Display) ClearScreen() error {
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("cmd", "/c", "cls")
	} else {
		cmd = exec.Command("clear")
	}
	cmd.Stdout = os.Stdout
	return cmd.Run()
}

// ShowProcessStatus shows the current process status
func (d *Display) ShowProcessStatus(message string) {
	fmt.Printf("\r%s", strings.Repeat(" ", 80)) // Clear line
	fmt.Printf("\r%s", color.CyanString("⚡ "+message))
}

// ShowPrivilegeError shows the privilege error message
func (d *Display) ShowPrivilegeError(errorMsg, adminMsg, sudoMsg, sudoExample string) {
	red := color.New(color.FgRed, color.Bold)
	yellow := color.New(color.FgYellow)

	red.Println(errorMsg)
	if runtime.GOOS == "windows" {
		yellow.Println(adminMsg)
	} else {
		yellow.Printf("%s\n%s\n", sudoMsg, fmt.Sprintf(sudoExample, os.Args[0]))
	}
}

// ShowSuccess shows a success message
func (d *Display) ShowSuccess(successMsg, restartMsg string) {
	green := color.New(color.FgGreen, color.Bold)
	yellow := color.New(color.FgYellow, color.Bold)

	green.Printf("\n%s\n", successMsg)
	yellow.Printf("%s\n", restartMsg)
}

// ShowError shows an error message
func (d *Display) ShowError(message string) {
	red := color.New(color.FgRed, color.Bold)
	red.Printf("\n%s\n", message)
}

// ShowWarning shows a warning message
func (d *Display) ShowWarning(message string) {
	yellow := color.New(color.FgYellow, color.Bold)
	yellow.Printf("\n%s\n", message)
}

// ShowInfo shows an info message
func (d *Display) ShowInfo(message string) {
	cyan := color.New(color.FgCyan)
	cyan.Printf("\n%s\n", message)
}

// ShowPrompt shows a prompt message and waits for user input
func (d *Display) ShowPrompt(message string) {
	fmt.Print(message)
	os.Stdout.Sync()
}
