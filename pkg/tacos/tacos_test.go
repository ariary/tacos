//go:build !windows

package tacos

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"math/big"
	"net"
	"os"
	"strings"
	"testing"
	"time"
)

// --- ShellArgs tests ---

func TestShellArgsBash(t *testing.T) {
	args := ShellArgs("/bin/bash")
	if len(args) != 1 || args[0] != "-li" {
		t.Errorf("ShellArgs(/bin/bash) = %v, want [-li]", args)
	}
}

func TestShellArgsBashSubstring(t *testing.T) {
	// "bash" substring should match even in unusual paths
	args := ShellArgs("/usr/local/bin/bash")
	if len(args) != 1 || args[0] != "-li" {
		t.Errorf("ShellArgs(/usr/local/bin/bash) = %v, want [-li]", args)
	}
}

func TestShellArgsZsh(t *testing.T) {
	args := ShellArgs("/bin/zsh")
	if len(args) != 1 || args[0] != "-i" {
		t.Errorf("ShellArgs(/bin/zsh) = %v, want [-i]", args)
	}
}

func TestShellArgsCsh(t *testing.T) {
	args := ShellArgs("/bin/csh")
	if len(args) != 1 || args[0] != "-i" {
		t.Errorf("ShellArgs(/bin/csh) = %v, want [-i]", args)
	}
}

func TestShellArgsTcsh(t *testing.T) {
	args := ShellArgs("/bin/tsh")
	if len(args) != 1 || args[0] != "-i" {
		t.Errorf("ShellArgs(/bin/tsh) = %v, want [-i]", args)
	}
}

func TestShellArgsSh(t *testing.T) {
	args := ShellArgs("/bin/sh")
	if len(args) != 1 || args[0] != "-i" {
		t.Errorf("ShellArgs(/bin/sh) = %v, want [-i]", args)
	}
}

func TestShellArgsUnknownShell(t *testing.T) {
	args := ShellArgs("/bin/fish")
	if args != nil {
		t.Errorf("ShellArgs(/bin/fish) = %v, want nil", args)
	}
}

func TestShellArgsEmptyString(t *testing.T) {
	args := ShellArgs("")
	if args != nil {
		t.Errorf("ShellArgs('') = %v, want nil", args)
	}
}

func TestShellArgsBashTakesPrecedenceOverSh(t *testing.T) {
	// "/bin/bash" contains both "bash" and "/sh" (no it doesn't -- but
	// this test verifies bash is checked first since bash is a superset)
	args := ShellArgs("/usr/bin/bash")
	if len(args) != 1 || args[0] != "-li" {
		t.Errorf("ShellArgs(/usr/bin/bash) = %v, want [-li]", args)
	}
}

// --- ConnectTLS tests ---

// generateSelfSignedCert creates an in-memory self-signed TLS certificate.
func generateSelfSignedCert(t *testing.T) tls.Certificate {
	t.Helper()
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("generate key: %s", err)
	}

	template := &x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject:      pkix.Name{CommonName: "test"},
		NotBefore:    time.Now(),
		NotAfter:     time.Now().Add(time.Hour),
		IPAddresses:  []net.IP{net.ParseIP("127.0.0.1")},
	}

	certDER, err := x509.CreateCertificate(rand.Reader, template, template, &key.PublicKey, key)
	if err != nil {
		t.Fatalf("create cert: %s", err)
	}

	return tls.Certificate{
		Certificate: [][]byte{certDER},
		PrivateKey:  key,
	}
}

// startTLSServer starts a TLS server that accepts one connection, performs the
// handshake, then closes it. It signals readiness via the ready channel.
func startTLSServer(t *testing.T) (addr string, done chan struct{}) {
	t.Helper()
	cert := generateSelfSignedCert(t)
	conf := &tls.Config{
		Certificates: []tls.Certificate{cert},
	}
	ln, err := tls.Listen("tcp", "127.0.0.1:0", conf)
	if err != nil {
		t.Fatalf("listen: %s", err)
	}

	done = make(chan struct{})
	go func() {
		defer ln.Close()
		defer close(done)
		conn, err := ln.Accept()
		if err != nil {
			return
		}
		// Complete the TLS handshake before closing
		tlsConn := conn.(*tls.Conn)
		tlsConn.Handshake()
		// Keep connection open briefly so client can complete its handshake too
		time.Sleep(100 * time.Millisecond)
		conn.Close()
	}()

	return ln.Addr().String(), done
}

func TestConnectTLSSuccess(t *testing.T) {
	addr, serverDone := startTLSServer(t)

	conn, err := ConnectTLS(addr, 5, 0)
	if err != nil {
		t.Fatalf("ConnectTLS failed: %s", err)
	}
	conn.Close()
	<-serverDone
}

func TestConnectTLSFailsOnBadHost(t *testing.T) {
	_, err := ConnectTLS("127.0.0.1:1", 1, 0)
	if err == nil {
		t.Fatal("ConnectTLS should have failed on bad host")
	}
	if !strings.Contains(err.Error(), "failed to connect") {
		t.Errorf("error should contain 'failed to connect', got: %s", err)
	}
}

func TestConnectTLSRetriesExhausted(t *testing.T) {
	_, err := ConnectTLS("127.0.0.1:1", 1, 2)
	if err == nil {
		t.Fatal("ConnectTLS should have failed after exhausting retries")
	}
	if !strings.Contains(err.Error(), "3 attempt(s)") {
		t.Errorf("error should mention 3 attempts, got: %s", err)
	}
}

func TestConnectTLSRetriesCountMatchesMaxRetries(t *testing.T) {
	// With maxRetries=0, should only try once
	_, err := ConnectTLS("127.0.0.1:1", 1, 0)
	if err == nil {
		t.Fatal("expected error")
	}
	if !strings.Contains(err.Error(), "1 attempt(s)") {
		t.Errorf("error should mention 1 attempt, got: %s", err)
	}
}

func TestConnectTLSErrorWrapsOriginal(t *testing.T) {
	_, err := ConnectTLS("127.0.0.1:1", 1, 0)
	if err == nil {
		t.Fatal("expected error")
	}
	// The error should wrap the original dial error
	if !strings.Contains(err.Error(), "connection refused") {
		t.Errorf("error should contain original cause, got: %s", err)
	}
}

// --- DetectDefaultShell tests ---

func TestDetectDefaultShellReturnsValidPath(t *testing.T) {
	shell := DetectDefaultShell()
	if shell == "" {
		t.Fatal("DetectDefaultShell returned empty string")
	}
	// Should start with / on Unix
	if !strings.HasPrefix(shell, "/") {
		t.Errorf("DetectDefaultShell returned %q, expected path starting with /", shell)
	}
	// The detected shell should actually exist
	if _, err := os.Stat(shell); err != nil {
		t.Errorf("DetectDefaultShell returned %q which doesn't exist: %s", shell, err)
	}
}

func TestDetectDefaultShellNoNewlines(t *testing.T) {
	shell := DetectDefaultShell()
	if strings.Contains(shell, "\n") {
		t.Errorf("DetectDefaultShell contains newline: %q", shell)
	}
}
