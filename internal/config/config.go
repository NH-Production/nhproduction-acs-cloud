package config

import (
	"fmt"
	"log/slog"
	"os"
	"strings"
)

type Config struct {
	Environment string
	HTTPAddr string
	DatabaseDSN string
	LogLevel slog.Level
}

func Load() (Config, error) {
	cfg := Config{Environment: valueOr("APP_ENV", "development"), HTTPAddr: valueOr("HTTP_ADDR", "127.0.0.1:18080"), DatabaseDSN: strings.TrimSpace(os.Getenv("DATABASE_DSN")), LogLevel: slog.LevelInfo}
	switch strings.ToLower(valueOr("LOG_LEVEL", "info")) {
	case "debug": cfg.LogLevel = slog.LevelDebug
	case "info": cfg.LogLevel = slog.LevelInfo
	case "warn", "warning": cfg.LogLevel = slog.LevelWarn
	case "error": cfg.LogLevel = slog.LevelError
	default: return Config{}, fmt.Errorf("LOG_LEVEL must be debug, info, warn, or error")
	}
	if strings.TrimSpace(cfg.HTTPAddr) == "" { return Config{}, fmt.Errorf("HTTP_ADDR must not be empty") }
	if strings.TrimSpace(cfg.Environment) == "" { return Config{}, fmt.Errorf("APP_ENV must not be empty") }
	return cfg, nil
}

func valueOr(key, fallback string) string {
	if value := strings.TrimSpace(os.Getenv(key)); value != "" { return value }
	return fallback
}
