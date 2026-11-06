package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

type Store struct { db *sql.DB }

func Open(ctx context.Context, dsn string) (*Store, error) {
	if dsn == "" { return nil, fmt.Errorf("database DSN is required") }
	db, err := sql.Open("mysql", dsn)
	if err != nil { return nil, fmt.Errorf("open MariaDB connection: %w", err) }
	db.SetMaxOpenConns(10); db.SetMaxIdleConns(5); db.SetConnMaxLifetime(5*time.Minute)
	if err := db.PingContext(ctx); err != nil { _ = db.Close(); return nil, fmt.Errorf("ping MariaDB: %w", err) }
	return &Store{db: db}, nil
}

func (s *Store) PingContext(ctx context.Context) error {
	if s == nil || s.db == nil { return fmt.Errorf("database is not configured") }
	return s.db.PingContext(ctx)
}
func (s *Store) Close() error {
	if s == nil || s.db == nil { return nil }
	return s.db.Close()
}
