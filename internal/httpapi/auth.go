package httpapi

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	"github.com/NH-Production/nhproduction-acs-cloud/internal/database"
	platformauth "github.com/NH-Production/nhproduction-acs-cloud/internal/platform/auth"
	"github.com/NH-Production/nhproduction-acs-cloud/internal/platform/tenant"
)

const sessionCookieName = "nhpc_session"

type loginRequest struct {
	Email string `json:"email"`
	Password string `json:"password"`
	TenantID uint64 `json:"tenant_id"`
}

func loginHandler(store *database.Store, secureCookies bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		r.Body = http.MaxBytesReader(w, r.Body, 8<<10)
		var input loginRequest
		if err := json.NewDecoder(r.Body).Decode(&input); err != nil || input.TenantID == 0 || strings.TrimSpace(input.Email) == "" || input.Password == "" {
			writeJSON(w, http.StatusBadRequest, healthResponse{Status:"invalid_request"}); return
		}
		user, err := store.FindUserCredential(r.Context(), strings.ToLower(strings.TrimSpace(input.Email)))
		if err != nil || user.Status != "active" || bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(input.Password)) != nil {
			writeJSON(w, http.StatusUnauthorized, healthResponse{Status:"invalid_credentials"}); return
		}
		allowed, err := store.UserCanAccessTenant(r.Context(), user.ID, input.TenantID)
		if err != nil { writeJSON(w, http.StatusInternalServerError, healthResponse{Status:"authentication_unavailable"}); return }
		if !allowed { writeJSON(w, http.StatusUnauthorized, healthResponse{Status:"invalid_credentials"}); return }
		token, tokenHash, expires, err := platformauth.NewSessionToken()
		if err != nil { writeJSON(w, http.StatusInternalServerError, healthResponse{Status:"session_unavailable"}); return }
		if err := store.CreateSession(r.Context(), user.ID, input.TenantID, tokenHash, expires); err != nil {
			writeJSON(w, http.StatusInternalServerError, healthResponse{Status:"session_unavailable"}); return
		}
		http.SetCookie(w, &http.Cookie{Name:sessionCookieName, Value:token, Path:"/", HttpOnly:true, Secure:secureCookies, SameSite:http.SameSiteStrictMode, Expires:expires, MaxAge:int(time.Until(expires).Seconds())})
		writeJSON(w, http.StatusOK, map[string]any{"status":"authenticated","user_id":user.ID,"email":user.Email,"tenant_id":input.TenantID})
	}
}

func sessionMiddleware(store *database.Store, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		cookie, err := r.Cookie(sessionCookieName)
		if err != nil || cookie.Value == "" { writeJSON(w, http.StatusUnauthorized, healthResponse{Status:"authentication_required"}); return }
		session, err := store.ResolveSession(r.Context(), platformauth.HashSessionToken(cookie.Value))
		if err != nil { writeJSON(w, http.StatusUnauthorized, healthResponse{Status:"authentication_required"}); return }
		ctx := platformauth.WithPrincipal(r.Context(), platformauth.Principal{UserID:session.ID, Email:session.Email, TenantID:session.TenantID})
		ctx = tenant.WithID(ctx, tenant.ID(session.TenantID))
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func logoutHandler(store *database.Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if cookie, err := r.Cookie(sessionCookieName); err == nil && cookie.Value != "" {
			if err := store.RevokeSession(r.Context(), platformauth.HashSessionToken(cookie.Value)); err != nil {
				writeJSON(w, http.StatusInternalServerError, healthResponse{Status:"logout_unavailable"}); return
			}
		}
		http.SetCookie(w, &http.Cookie{Name:sessionCookieName, Value:"", Path:"/", HttpOnly:true, Secure:r.TLS != nil, SameSite:http.SameSiteStrictMode, MaxAge:-1})
		writeJSON(w, http.StatusOK, healthResponse{Status:"logged_out"})
	}
}

func permissionMiddleware(store *database.Store, permission string, next http.Handler) http.Handler {
	return sessionMiddleware(store, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		principal, ok := platformauth.FromContext(r.Context())
		if !ok { writeJSON(w, http.StatusUnauthorized, healthResponse{Status:"authentication_required"}); return }
		allowed, err := store.HasPermission(r.Context(), principal.UserID, principal.TenantID, permission)
		if err != nil { writeJSON(w, http.StatusInternalServerError, healthResponse{Status:"authorization_unavailable"}); return }
		if !allowed { writeJSON(w, http.StatusForbidden, healthResponse{Status:"permission_denied"}); return }
		next.ServeHTTP(w, r)
	}))
}
