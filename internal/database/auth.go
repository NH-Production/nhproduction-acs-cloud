package database

import (
	"context"
	"errors"
	"time"
)

var ErrInvalidCredentials = errors.New("invalid credentials")

type UserCredential struct {
	ID uint64
	Email string
	PasswordHash string
	Status string
}

type SessionUser struct {
	ID uint64
	Email string
	TenantID uint64
}

func (s *Store) FindUserCredential(ctx context.Context, email string) (UserCredential, error) {
	var user UserCredential
	err := s.db.QueryRowContext(ctx,
		"SELECT id, email, password_hash, status FROM users WHERE email = ? LIMIT 1", email,
	).Scan(&user.ID, &user.Email, &user.PasswordHash, &user.Status)
	if err != nil { return UserCredential{}, err }
	return user, nil
}

func (s *Store) UserCanAccessTenant(ctx context.Context, userID, tenantID uint64) (bool, error) {
	var allowed bool
	err := s.db.QueryRowContext(ctx, `
		SELECT EXISTS(
			SELECT 1
			FROM tenants t
			JOIN user_roles ur ON ur.user_id = ?
			JOIN roles r ON r.id = ur.role_id
			WHERE t.id = ?
			  AND t.status = 'active'
			  AND (ur.tenant_id = t.id OR ur.tenant_id IS NULL)
			  AND (r.tenant_id = t.id OR r.tenant_id IS NULL)
		)`, userID, tenantID).Scan(&allowed)
	return allowed, err
}

func (s *Store) CreateSession(ctx context.Context, userID, tenantID uint64, tokenHash string, expiresAt time.Time) error {
	_, err := s.db.ExecContext(ctx,
		"INSERT INTO user_sessions (user_id, tenant_id, token_hash, expires_at) VALUES (?, ?, ?, ?)",
		userID, tenantID, tokenHash, expiresAt.UTC())
	return err
}

func (s *Store) ResolveSession(ctx context.Context, tokenHash string) (SessionUser, error) {
	var user SessionUser
	err := s.db.QueryRowContext(ctx, `
		SELECT u.id, u.email, s.tenant_id
		FROM user_sessions s
		JOIN users u ON u.id = s.user_id
		JOIN tenants t ON t.id = s.tenant_id
		WHERE s.token_hash = ?
		  AND s.revoked_at IS NULL
		  AND s.expires_at > UTC_TIMESTAMP(3)
		  AND u.status = 'active'
		  AND t.status = 'active'
		  AND EXISTS (
			SELECT 1
			FROM user_roles ur
			JOIN roles r ON r.id = ur.role_id
			WHERE ur.user_id = u.id
			  AND (ur.tenant_id = s.tenant_id OR ur.tenant_id IS NULL)
			  AND (r.tenant_id = s.tenant_id OR r.tenant_id IS NULL)
		  )
		LIMIT 1`, tokenHash).Scan(&user.ID, &user.Email, &user.TenantID)
	if err != nil { return SessionUser{}, err }
	if _, err := s.db.ExecContext(ctx, "UPDATE user_sessions SET last_seen_at = UTC_TIMESTAMP(3) WHERE token_hash = ?", tokenHash); err != nil {
		return SessionUser{}, err
	}
	return user, nil
}

func (s *Store) RevokeSession(ctx context.Context, tokenHash string) error {
	_, err := s.db.ExecContext(ctx,
		"UPDATE user_sessions SET revoked_at = UTC_TIMESTAMP(3) WHERE token_hash = ? AND revoked_at IS NULL", tokenHash)
	return err
}

func (s *Store) HasPermission(ctx context.Context, userID, tenantID uint64, permission string) (bool, error) {
	var allowed bool
	err := s.db.QueryRowContext(ctx, `
		SELECT EXISTS(
			SELECT 1
			FROM user_roles ur
			JOIN roles r ON r.id = ur.role_id
			JOIN role_permissions rp ON rp.role_id = r.id
			JOIN permissions p ON p.id = rp.permission_id
			WHERE ur.user_id = ?
			  AND (ur.tenant_id = ? OR ur.tenant_id IS NULL)
			  AND (r.tenant_id = ? OR r.tenant_id IS NULL)
			  AND p.permission_key = ?
		)`, userID, tenantID, tenantID, permission).Scan(&allowed)
	return allowed, err
}

