package auth

import (
	"testing"
	"time"
)

func TestNewSessionTokenIsOpaqueAndHashed(t *testing.T) {
	token, hash, expires, err := NewSessionToken()
	if err != nil { t.Fatal(err) }
	if len(token) != 64 || len(hash) != 64 { t.Fatalf("unexpected token/hash length: %d/%d", len(token), len(hash)) }
	if token == hash || HashSessionToken(token) != hash { t.Fatal("session hash mismatch") }
	if !expires.After(time.Now().UTC()) { t.Fatal("session expiry must be in the future") }
}
