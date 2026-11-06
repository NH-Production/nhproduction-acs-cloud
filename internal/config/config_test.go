package config

import (
	"log/slog"
	"testing"
)

func TestLoadDefaults(t *testing.T) {
	t.Setenv("APP_ENV", ""); t.Setenv("HTTP_ADDR", ""); t.Setenv("DATABASE_DSN", ""); t.Setenv("LOG_LEVEL", "")
	got, err := Load()
	if err != nil { t.Fatalf("Load() error = %v", err) }
	if got.Environment != "development" || got.HTTPAddr != "127.0.0.1:18080" { t.Fatalf("unexpected defaults: %+v", got) }
	if got.LogLevel != slog.LevelInfo { t.Fatalf("LogLevel = %v, want info", got.LogLevel) }
}

func TestLoadRejectsInvalidLogLevel(t *testing.T) {
	t.Setenv("LOG_LEVEL", "trace")
	if _, err := Load(); err == nil { t.Fatal("expected invalid LOG_LEVEL error") }
}
