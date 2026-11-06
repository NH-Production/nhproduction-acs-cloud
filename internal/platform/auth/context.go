package auth

import "context"

type Principal struct {
	UserID uint64
	Email string
	TenantID uint64
}

type principalKey struct{}

func WithPrincipal(ctx context.Context, principal Principal) context.Context {
	return context.WithValue(ctx, principalKey{}, principal)
}

func FromContext(ctx context.Context) (Principal, bool) {
	principal, ok := ctx.Value(principalKey{}).(Principal)
	return principal, ok && principal.UserID > 0 && principal.TenantID > 0
}
