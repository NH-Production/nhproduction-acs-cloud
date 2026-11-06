package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/NH-Production/nhproduction-acs-cloud/internal/config"
	"github.com/NH-Production/nhproduction-acs-cloud/internal/database"
	"github.com/NH-Production/nhproduction-acs-cloud/internal/httpapi"
)

func main() {
	cfg, err := config.Load()
	if err != nil { slog.Error("invalid configuration", "error", err); os.Exit(1) }
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: cfg.LogLevel})))

	var db *database.Store
	if cfg.DatabaseDSN != "" {
		ctx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
		db, err = database.Open(ctx, cfg.DatabaseDSN)
		cancel()
		if err != nil { slog.Error("database connection failed", "error", err); os.Exit(1) }
		defer db.Close()
	} else { slog.Warn("DATABASE_DSN is empty; readiness remains unavailable") }

	server := &http.Server{Addr: cfg.HTTPAddr, Handler: httpapi.NewRouter(db), ReadHeaderTimeout: 5*time.Second, ReadTimeout: 15*time.Second, WriteTimeout: 15*time.Second, IdleTimeout: 60*time.Second}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	go func() {
		slog.Info("HTTP server starting", "addr", cfg.HTTPAddr, "environment", cfg.Environment)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) { slog.Error("HTTP server stopped", "error", err); stop() }
	}()
	<-ctx.Done()
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := server.Shutdown(shutdownCtx); err != nil { slog.Error("graceful shutdown failed", "error", err); _ = server.Close() }
}
