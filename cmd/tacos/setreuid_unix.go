//go:build !windows

package main

import "syscall"

func applySetreuid() {
	euid := syscall.Geteuid()
	syscall.Setreuid(euid, euid)
}
