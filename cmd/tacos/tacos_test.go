package main

import (
	"os/exec"
	"strings"
	"testing"
)

// buildBinary builds the tacos binary for testing and returns its path.
func buildBinary(t *testing.T) string {
	t.Helper()
	bin := t.TempDir() + "/tacos"
	cmd := exec.Command("go", "build", "-o", bin, ".")
	cmd.Dir = "."
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("build failed: %s\n%s", err, out)
	}
	return bin
}

func TestVersionFlag(t *testing.T) {
	bin := buildBinary(t)
	out, err := exec.Command(bin, "--version").CombinedOutput()
	if err != nil {
		t.Fatalf("--version failed: %s\n%s", err, out)
	}
	output := strings.TrimSpace(string(out))
	if !strings.HasPrefix(output, "tacos ") {
		t.Errorf("--version output = %q, want prefix 'tacos '", output)
	}
}

func TestVersionFlagWithLdflags(t *testing.T) {
	bin := t.TempDir() + "/tacos"
	cmd := exec.Command("go", "build", "-ldflags", "-X 'main.Version=1.2.3'", "-o", bin, ".")
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("build with ldflags failed: %s\n%s", err, out)
	}

	result, err := exec.Command(bin, "--version").CombinedOutput()
	if err != nil {
		t.Fatalf("--version failed: %s\n%s", err, result)
	}
	output := strings.TrimSpace(string(result))
	if output != "tacos 1.2.3" {
		t.Errorf("--version output = %q, want 'tacos 1.2.3'", output)
	}
}

func TestNoArgsShowsUsage(t *testing.T) {
	bin := buildBinary(t)
	out, err := exec.Command(bin).CombinedOutput()
	if err == nil {
		t.Fatal("expected non-zero exit code with no args")
	}
	output := string(out)
	if !strings.Contains(output, "Usage:") {
		t.Errorf("output should contain 'Usage:', got: %s", output)
	}
	if !strings.Contains(output, "-timeout") {
		t.Errorf("output should list -timeout flag, got: %s", output)
	}
	if !strings.Contains(output, "-retry") {
		t.Errorf("output should list -retry flag, got: %s", output)
	}
}

func TestBakedInRemoteViaLdflags(t *testing.T) {
	bin := t.TempDir() + "/tacos"
	// Build with baked-in remote pointing to nowhere
	cmd := exec.Command("go", "build", "-ldflags", "-X 'main.Remote=127.0.0.1:1'", "-o", bin, ".")
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("build failed: %s\n%s", err, out)
	}

	// Run without arguments -- should NOT show usage since Remote is baked in
	// It will fail to connect, but the exit should be from connection failure, not usage
	result, err := exec.Command(bin, "--timeout", "1").CombinedOutput()
	output := string(result)
	if err == nil {
		t.Fatal("expected non-zero exit (connection failure)")
	}
	// Should NOT contain "Usage:" since Remote was provided via ldflags
	if strings.Contains(output, "Usage:") {
		t.Error("with baked-in Remote, should not show usage")
	}
}
