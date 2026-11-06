package httpapi

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/NH-Production/nhproduction-acs-cloud/internal/database"
)

func TestSessionMiddlewareRejectsMissingCookie(t *testing.T) {
	handler := sessionMiddleware(nil, http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusNoContent) }))
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/private", nil))
	if rec.Code != http.StatusUnauthorized { t.Fatalf("status = %d, want 401", rec.Code) }
}

func TestLogoutWithoutCookieStillClearsSession(t *testing.T) {
	handler := logoutHandler(nil, false)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/api/v1/auth/logout", nil))
	if rec.Code != http.StatusOK { t.Fatalf("status = %d, want 200", rec.Code) }
	if len(rec.Result().Cookies()) == 0 { t.Fatal("expected session cookie clearing header") }
}

var _ *database.Store
