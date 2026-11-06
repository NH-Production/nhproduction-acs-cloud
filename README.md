# NHProduction ACS Cloud

Multi-tenant ACS management SaaS built around an existing shared GenieACS deployment.

## Approved baseline
- Hybrid SaaS Control Plane + existing GenieACS Data Plane.
- One shared GenieACS instance for ISP tenants.
- Incrementing tenant ingress ports and tenant-specific subdomains under `acs.network-nh.cloud`.
- MariaDB for SaaS metadata; GenieACS MongoDB remains separate.
- Initial planning target: 1,000 devices; capacity is not yet benchmarked or guaranteed.
- Preserve the existing VPS and all current services.

## Documentation
- [SRS](docs/SRS.md) · [Architecture](docs/ARCHITECTURE.md)
- [Tenant isolation](docs/MULTI-TENANT-ISOLATION.md) · [Port allocation](docs/PORT-ALLOCATION.md)
- [Database schema](docs/DATABASE-SCHEMA.md) · [Security](docs/SECURITY.md)
- [Deployment policy](docs/DEPLOYMENT.md) · [Installation guide](docs/INSTALLATION.md)
- [Read-only server audit](docs/SERVER-AUDIT.md) · [Roadmap](docs/ROADMAP.md)

## Scripts
- `bash scripts/preflight.sh` — read-only host inventory.
- `scripts/install-staging.sh` — staging-only installer for a future pre-built release bundle; requires explicit `--apply`.
- `scripts/rollback-staging.sh` — explicit staging application-code rollback.

The application runtime and build pipeline are not yet implemented. The installer is scaffolding and cannot install a runnable product until a real release bundle is produced.

## Safety boundary
PR #1 does not authorize production changes. Do not change existing VPS services, DNS, firewall, Nginx, GenieACS, MongoDB or MariaDB. No merge or deployment without completed tests and explicit owner approval.
