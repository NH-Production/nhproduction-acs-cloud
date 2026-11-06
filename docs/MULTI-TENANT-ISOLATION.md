# Multi-tenant isolation — shared GenieACS

## Decision
All ISP tenants share one GenieACS process and its GenieACS data store in the initial design. Per-tenant ports and subdomains are routing allocations, not independent GenieACS instances and not data-isolation boundaries.

## Required isolation controls
1. Every SaaS-owned record carries a non-null tenant_id where applicable.
2. Tenant context is derived from the authenticated principal and server-side tenant membership.
3. Every device read, write, export, event, metric, task and notification is scoped by verified ownership.
4. Device enrollment is a controlled state machine: discovered/unclaimed → pending verification → verified/assigned → active; rejected or revoked devices cannot be used by a tenant.
5. Serial number alone is not sufficient proof of ownership.
6. Backend is the only tenant-facing caller of GenieACS NBI.
7. Tenant users cannot select arbitrary GenieACS IDs, NBI URLs, MongoDB collections or raw commands.
8. Cross-tenant negative authorization tests are mandatory.
9. Platform administrators' cross-tenant access is privileged and audited.
10. Tenant suspension blocks portal operations according to policy but does not delete ACS records or interrupt CWMP unless a separately approved policy explicitly requires it.

## Shared-data caveat
GenieACS itself is not assumed to enforce NHProduction tenant boundaries. The SaaS ownership registry and backend authorization layer must enforce them. Any query against GenieACS must be joined to or checked against the trusted ownership registry before tenant data is exposed.

## Ingress attribution gate
Different hostnames/ports can route traffic to the same listener. They do not automatically tell the application which ISP owns a device. Before implementation, demonstrate a trusted, end-to-end attribution method that cannot be forged by a CPE or external client. If not possible, require explicit enrollment verification and do not infer tenant from port alone.

## Required security tests
- Tenant A cannot list, view, search, export or operate Tenant B devices.
- Tenant A cannot access Tenant B events, metrics, provisioning profiles, API keys or invoices.
- Changing device IDs, tenant IDs, hostname, port or request headers cannot bypass authorization.
- Unassigned and pending devices are not visible to tenant users.
- Revoked ownership immediately blocks subsequent tenant API access.
