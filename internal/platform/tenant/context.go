package tenant

import "context"

type contextKey struct{}
type ID uint64

func WithID(ctx context.Context, id ID) context.Context { return context.WithValue(ctx, contextKey{}, id) }
func FromContext(ctx context.Context) (ID, bool) {
	id, ok := ctx.Value(contextKey{}).(ID)
	return id, ok && id > 0
}
