# Authentication and RBAC foundation (PR #3)

## Implemented foundation
- Password verification with bcrypt against users.password_hash.
- Login requires email, password, and tenant_id. The tenant membership is checked against user_roles and roles in MariaDB; client-supplied tenant_id is not trusted without that lookup.
- Random 256-bit opaque session tokens. Only SHA-256 token hashes are stored in MariaDB.
- 12-hour server-side sessions with expiry, revocation, and active user/tenant checks on authenticated requests.
- HttpOnly, SameSite=Strict cookie; Secure is enabled when APP_ENV=production.
- POST /api/v1/auth/login, POST /api/v1/auth/logout, GET /api/v1/auth/me, and protected GET /api/v1/tenant.
- Permission lookup joins user_roles, roles, role_permissions, and permissions. The permission middleware is available for management routes in subsequent work.

## Database
Review database/migrations/003_user_sessions.sql and apply it only to a disposable staging database using a reviewed migration process. This PR does not execute migrations automatically. Existing accounts need bcrypt password hashes and active user_roles membership for the requested tenant.

## Security limitations and next gates
- Login rate limiting, password reset/invitation flows, MFA, session rotation, CSRF token/Origin validation, audit logging, and session cleanup are not implemented.
- Configure HTTPS at a reviewed reverse proxy. Secure cookies are enabled only when APP_ENV=production; do not expose the service directly.
- Seed a permission catalogue and enforce permissionMiddleware on actual management routes in a later PR.
- Password hash creation and account provisioning are not exposed as public endpoints.
- Cross-tenant integration tests, MariaDB migration tests, security review, and secret-management review remain mandatory.
- Do not run this service against the existing production database or deploy it to the current VPS.
