package main

import (
	"github.com/ariary/tacos/pkg/tacos"
)

func main() {
	//Determine default shell
	//macOS
	//dscl . -read ~/ UserShell
	//linux
	//grep ^$(id -un): /etc/passwd | cut -d : -f 7-
	tacos.DefaultShell()
}
