# Software Requirements Specification — NHProduction ACS Cloud

## 1. Purpose
NHProduction ACS Cloud is a subscription-based multi-tenant ACS management SaaS. It provides ISP tenants with a controlled portal to manage their own customer-premises equipment (CPE) through an existing GenieACS deployment.

## 2. Approved baseline decisions
- Product: NHProduction ACS Cloud.
- Architecture: hybrid SaaS Control Plane + GenieACS Data Plane.
- Tenant ACS model: one shared GenieACS instance.
- Tenant ingress: incrementing port allocation, exposed through tenant-specific subdomains under `acs.network-nh.cloud` (parent domain: `network-nh.cloud`).
- Existing VPS and GenieACS installation must be preserved.
- Initial design capacity target: 1,000 devices; this is a planning target, not a performance guarantee.
- Billing: subscription.
- No merge or production deployment without explicit owner approval.

## 3. Actors and roles
- Platform Super Admin: manages tenants, shared ACS integration, plans, platform settings and audit.
- ISP Owner/Admin: manages their tenant users, devices, provisioning profiles and subscription.
- ISP Operator/Technician: performs permitted device operations and views assigned tenant data.
- Billing Operator: manages invoices and payment status within assigned scope.
- CPE: connects to the assigned tenant ingress endpoint using CWMP.

## 4. Functional requirements
### Tenant lifecycle
- Create, review, activate, suspend and archive ISP tenants.
- Allocate a unique tenant slug, subdomain and ingress port.
- Prevent duplicate slug, hostname and port allocation.
- Enforce tenant status and subscription entitlement on every tenant API request.

### Identity and access
- Authenticate users securely.
- Support platform and tenant-scoped RBAC.
- Enforce tenant scope server-side; never trust tenant_id supplied by a browser.
- Record privileged and device-control actions in an audit log.

### Device lifecycle
- Enroll and verify devices before assigning tenant ownership.
- Display device identity, model, manufacturer, connection state, last inform and permitted parameter summaries.
- Support search, filters, pagination, events and metrics.
- Support controlled actions such as refresh and reboot, subject to authorization and audit.
- Prevent cross-tenant device lookup, mutation, export and event access.

### GenieACS integration
- Use one shared GenieACS instance for the approved baseline.
- Keep NBI, UI and MongoDB private to the server/internal network.
- Route all SaaS operations through a backend integration service.
- Apply timeouts, rate limits, validation and audit around NBI operations.
- Do not allow tenant users to provide arbitrary NBI URLs or commands.

### Subscription and billing
- Define plans, device quotas, subscription periods and tenant entitlements.
- Generate invoices and record manual or integrated payment references.
- Enforce quota and suspension policy explicitly; never delete tenant devices on suspension.
- Keep payment state changes auditable.

### Platform operations
- Provide platform health and tenant usage views.
- Support backup/restore procedures and operational runbooks.
- Expose health checks without leaking secrets or internal service details.

## 5. Non-functional requirements
- Tenant isolation is a security requirement, not a UI-only filter.
- TLS for public endpoints.
- Secrets stored outside source control.
- Structured logs with correlation IDs and redaction.
- Database migrations must be reversible where practical and backed up before production use.
- API pagination, bounded queries, timeouts and rate limits.
- Accessibility and responsive dashboard behavior.
- Capacity claims require repeatable load tests on the target infrastructure.

## 6. Out of scope for PR #1
- Installing or upgrading GenieACS.
- Creating extra GenieACS instances.
- Changing live DNS, firewall, ports, Nginx, systemd or database configuration.
- Enrolling real customer devices.
- Processing real payments.
- Production deployment or migration.

## 7. Acceptance criteria
- Architecture and isolation boundaries are documented.
- Tenant/subdomain/port lifecycle and conflict behavior are specified.
- Database schema includes tenant ownership and auditability.
- Security requirements explicitly cover device enrollment and cross-tenant access.
- Existing VPS preservation and approval gates are documented.
- Documentation checks pass in CI before review.
