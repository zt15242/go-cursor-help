package ui

import (
	"github.com/fatih/color"
)

const cyberpunkLogo = `
   ______                           ______ ______
  / ____/_  __________  ___  _____/ __/ // / / /
 / /   / / / / ___/ _ \/ __ \/ ___/ /_/ // /_/ / 
/ /___/ /_/ / /  /  __/ /_/ (__  ) __/__  __/ /  
\____/\__,_/_/   \___/\____/____/_/    /_/ /_/   
                                                  
`

// ShowLogo displays the cyberpunk-style logo
func (d *Display) ShowLogo() {
	cyan := color.New(color.FgCyan, color.Bold)
	cyan.Println(cyberpunkLogo)
}
