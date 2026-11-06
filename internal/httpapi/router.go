package httpapi

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/NH-Production/nhproduction-acs-cloud/internal/database"
	"github.com/NH-Production/nhproduction-acs-cloud/internal/platform/tenant"
)

type healthResponse struct { Status string `json:"status"` }
type tenantResponse struct { TenantID uint64 `json:"tenant_id"` }

func NewRouter(store *database.Store) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) { writeJSON(w, http.StatusOK, healthResponse{Status:"ok"}) })
	mux.HandleFunc("GET /readyz", func(w http.ResponseWriter, r *http.Request) {
		if store == nil { writeJSON(w, http.StatusServiceUnavailable, healthResponse{Status:"database_not_configured"}); return }
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second); defer cancel()
		if err := store.PingContext(ctx); err != nil { writeJSON(w, http.StatusServiceUnavailable, healthResponse{Status:"database_unavailable"}); return }
		writeJSON(w, http.StatusOK, healthResponse{Status:"ready"})
	})
	mux.Handle("GET /api/v1/tenant", requireTenant(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id, _ := tenant.FromContext(r.Context()); writeJSON(w, http.StatusOK, tenantResponse{TenantID:uint64(id)})
	})))
	return mux
}

func requireTenant(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if _, ok := tenant.FromContext(r.Context()); !ok { writeJSON(w, http.StatusUnauthorized, healthResponse{Status:"authentication_required"}); return }
		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
