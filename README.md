# NHProduction ACS Cloud

Multi-tenant ACS management platform built around an existing shared GenieACS deployment.

## Current design decisions

- Architecture: hybrid SaaS control plane with an existing GenieACS data plane.
- GenieACS tenancy model: one shared GenieACS instance.
- Tenant ingress: unique incrementing port allocation, routed through tenant-specific subdomains.
- Domain: `network-nh.cloud`.
- Initial design target: 1,000 devices; capacity is not yet benchmarked or guaranteed.
- Infrastructure: preserve the existing VPS and services. No production changes are part of the foundation phase.

## Documentation

- [Software Requirements Specification](docs/SRS.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Multi-tenant isolation](docs/MULTI-TENANT-ISOLATION.md)
- [Port and subdomain allocation](docs/PORT-ALLOCATION.md)
- [Database schema](docs/DATABASE-SCHEMA.md)
- [Security](docs/SECURITY.md)
- [Deployment and operations](docs/DEPLOYMENT.md)
- [Server audit checklist](docs/SERVER-AUDIT.md)
- [Roadmap](docs/ROADMAP.md)

## Safety boundary

This repository's foundation work does not authorize changes to the existing VPS, DNS, firewall, Nginx, GenieACS, MongoDB, or MariaDB. No merge or deployment without explicit owner approval.
