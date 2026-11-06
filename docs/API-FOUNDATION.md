# Go API foundation (PR #2)

## Scope
This PR establishes the first compilable Go API service skeleton. It is not production-ready and does not implement login, sessions, RBAC, tenant provisioning, billing, GenieACS NBI operations, or a migration runner.

## Runtime and configuration
- Go 1.23+
- MariaDB 10.6+ via github.com/go-sql-driver/mysql
- HTTP listener defaults to 127.0.0.1:18080
- APP_ENV defaults to development.
- HTTP_ADDR controls the bind address; keep loopback behind a reviewed reverse proxy.
- DATABASE_DSN is the MariaDB DSN. If set, startup must successfully ping MariaDB.
- LOG_LEVEL accepts debug, info, warn, or error.

Use a DSN with parseTime=true and a UTC session, e.g. app_user:REDACTED@tcp(127.0.0.1:3306)/nhproduction_acs_cloud?parseTime=true&charset=utf8mb4&loc=UTC. Never commit or paste real credentials. Store secrets in a protected environment file.

## Endpoints
- GET /healthz: process liveness only; does not imply database readiness.
- GET /readyz: returns 200 only when MariaDB is configured and responds to ping; otherwise 503.
- GET /api/v1/tenant: protected placeholder; returns 401 until trusted authentication middleware supplies server-side tenant context.

The API does not accept X-Tenant-ID or request-body tenant IDs as identity. tenant.WithID is an integration seam for future verified authentication middleware; it must never be called from untrusted request data.

## Data-plane boundary
The service does not expose GenieACS NBI, MongoDB, MariaDB, or GenieACS UI. NBI integration must be added behind a server-side client with fixed private endpoints, secret references, timeouts, and authorization checks.

## Local validation
Run go test ./..., go test -race ./..., and go vet ./.... No migration is run automatically. Do not point this foundation build at the existing production database or start it on the existing VPS.
