# Roadmap

## PR #1 — Foundation & Documentation
- Product README and approved architecture decisions.
- SRS, shared-tenant isolation, ingress/subdomain allocation, logical database schema.
- Security, deployment, read-only server audit and roadmap documentation.
- Documentation CI and review checklist.
- No runtime code, production configuration or deployment.

## PR #2 — Backend foundation
- Go project structure, configuration validation, health endpoints and structured logging.
- Unit tests and CI.
- No GenieACS write operations.

## PR #3 — Identity and tenant foundation
- Authentication, tenant membership, RBAC and audit trail.
- Cross-tenant negative tests.

## PR #4 — ACS integration read path
- Private NBI client, timeouts, safe read operations and ownership reconciliation.
- Contract tests using a non-production fixture.

## PR #5 — Device enrollment and tenant portal
- Verified enrollment, device list/detail, tenant-scoped events and metrics.

## PR #6 — Controlled device operations
- Permission-gated refresh/reboot, confirmation, rate limiting and audit.

## PR #7 — Subscription and billing
- Plans, quotas, invoices, payment records and entitlement enforcement.

## PR #8 — Performance and release readiness
- Load tests against a representative staging environment, security review, backup/restore drill and deployment plan.

Every PR requires tests and owner review. Merge and production deployment remain blocked until explicit owner approval.
