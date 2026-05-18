//go:build windows

package main

func applySetreuid() {
	// setreuid is not available on Windows
}
