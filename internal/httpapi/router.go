package httpapi

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/NH-Production/nhproduction-acs-cloud/internal/database"
	platformauth "github.com/NH-Production/nhproduction-acs-cloud/internal/platform/auth"
	"github.com/NH-Production/nhproduction-acs-cloud/internal/platform/tenant"
)

type healthResponse struct { Status string `json:"status"` }
type tenantResponse struct { TenantID uint64 `json:"tenant_id"` }

func NewRouter(store *database.Store) http.Handler { return NewRouterWithConfig(store, false) }

func NewRouterWithConfig(store *database.Store, secureCookies bool) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) { writeJSON(w, http.StatusOK, healthResponse{Status:"ok"}) })
	mux.HandleFunc("GET /readyz", func(w http.ResponseWriter, r *http.Request) {
		if store == nil { writeJSON(w, http.StatusServiceUnavailable, healthResponse{Status:"database_not_configured"}); return }
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second); defer cancel()
		if err := store.PingContext(ctx); err != nil { writeJSON(w, http.StatusServiceUnavailable, healthResponse{Status:"database_unavailable"}); return }
		writeJSON(w, http.StatusOK, healthResponse{Status:"ready"})
	})
	if store != nil {
		mux.HandleFunc("POST /api/v1/auth/login", loginHandler(store, secureCookies))
		mux.HandleFunc("POST /api/v1/auth/logout", logoutHandler(store, secureCookies))
		mux.Handle("GET /api/v1/auth/me", sessionMiddleware(store, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			principal, _ := platformauth.FromContext(r.Context())
			writeJSON(w, http.StatusOK, map[string]any{"user_id":principal.UserID,"email":principal.Email,"tenant_id":principal.TenantID})
		})))
		mux.Handle("GET /api/v1/tenant", sessionMiddleware(store, http.HandlerFunc(tenantHandler)))
	} else {
		unavailable := func(w http.ResponseWriter, _ *http.Request) { writeJSON(w, http.StatusServiceUnavailable, healthResponse{Status:"database_not_configured"}) }
		mux.HandleFunc("POST /api/v1/auth/login", unavailable)
		mux.HandleFunc("POST /api/v1/auth/logout", unavailable)
		mux.HandleFunc("GET /api/v1/auth/me", unavailable)
		mux.HandleFunc("GET /api/v1/tenant", unavailable)
	}
	return mux
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}


func tenantHandler(w http.ResponseWriter, r *http.Request) {
	id, _ := tenant.FromContext(r.Context())
	writeJSON(w, http.StatusOK, tenantResponse{TenantID: uint64(id)})
}
