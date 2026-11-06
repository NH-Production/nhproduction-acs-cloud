package tenant

import ("context"; "testing")

func TestFromContextRequiresPositiveServerContextID(t *testing.T) {
	if _, ok := FromContext(context.Background()); ok { t.Fatal("tenant context unexpectedly present") }
	if _, ok := FromContext(WithID(context.Background(), 0)); ok { t.Fatal("zero tenant ID must be rejected") }
	got, ok := FromContext(WithID(context.Background(), 42))
	if !ok || got != 42 { t.Fatalf("FromContext() = (%d, %v), want (42, true)", got, ok) }
}
