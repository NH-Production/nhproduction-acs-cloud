package httpapi

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"context"

	"github.com/NH-Production/nhproduction-acs-cloud/internal/platform/tenant"
)

func TestHealthEndpoint(t *testing.T) {
	rec := httptest.NewRecorder()
	NewRouter(nil).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", rec.Code)
	}
}

func TestReadinessFailsClosedWithoutDatabase(t *testing.T) {
	rec := httptest.NewRecorder()
	NewRouter(nil).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/readyz", nil))
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want 503", rec.Code)
	}
}

func TestTenantEndpointFailsClosedWithoutDatabase(t *testing.T) {
	rec := httptest.NewRecorder()
	NewRouter(nil).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/api/v1/tenant", nil))
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want 503", rec.Code)
	}
}

func TestTenantHeaderCannotBypassDatabaseRequirement(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/api/v1/tenant", nil)
	req.Header.Set("X-Tenant-ID", "999")
	rec := httptest.NewRecorder()
	NewRouter(nil).ServeHTTP(rec, req)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want 503", rec.Code)
	}
	if got := rec.Body.String(); got != "{\"status\":\"database_not_configured\"}\n" {
		t.Fatalf("body = %q", got)
	}
}

func TestTenantHandlerUsesContextNotRequestHeader(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/api/v1/tenant", nil)
	req.Header.Set("X-Tenant-ID", "999")
	req = req.WithContext(tenant.WithID(context.Background(), 7))
	rec := httptest.NewRecorder()
	tenantHandler(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", rec.Code)
	}
	if got := rec.Body.String(); got != "{\"tenant_id\":7}\n" {
		t.Fatalf("body = %q", got)
	}
}
