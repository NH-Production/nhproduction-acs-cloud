# Roadmap

## PR #1 — Foundation, documentation and safe installation scaffolding
- Product README, approved architecture and SRS.
- Shared GenieACS tenant isolation, ingress/subdomain allocation and logical database schema.
- Security, deployment, read-only server audit and roadmap documentation.
- Read-only preflight script.
- Staging-only installer and application-code rollback script for a future real release bundle.
- systemd unit template and environment example.
- CI documentation and shell syntax checks.
- No runtime application implementation, production configuration or deployment.

## PR #2 — Backend foundation
- Go project structure, configuration validation, health endpoints and structured logging.
- Reproducible build producing the documented release bundle.
- Unit tests and CI; no GenieACS write operations.

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
- Load tests on representative staging infrastructure, security review, backup/restore drill and deployment plan.

Every PR requires tests and owner review. Merge and production deployment remain blocked until explicit owner approval.
