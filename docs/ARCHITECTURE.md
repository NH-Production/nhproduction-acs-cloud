# Architecture

## 1. Logical topology
The platform is split into a SaaS Control Plane and an ACS Data Plane.

- Control Plane: web frontend, Go API, authentication/RBAC, tenant registry, subscription/billing, device ownership registry, audit and reporting.
- Tenant ingress gateway: maps a tenant hostname and allocated TCP port to the shared CWMP listener. It must not trust client-supplied tenant headers.
- ACS Data Plane: the existing shared GenieACS CWMP, NBI, UI and MongoDB services.
- SaaS database: MariaDB stores platform and tenant metadata; it remains logically separate from GenieACS MongoDB.

## 2. Request flow
1. CPE resolves its tenant ACS hostname and connects to the assigned ingress port.
2. Network edge/gateway accepts the connection and forwards CWMP to the single shared GenieACS CWMP listener.
3. GenieACS receives and stores device sessions in its shared data store.
4. Backend integration reads device data through private NBI.
5. Backend resolves device ownership using the enrollment/ownership registry and validates tenant scope before returning data or issuing operations.
6. All tenant-facing actions are authenticated, authorized, rate-limited and audited.

## 3. Important protocol constraint
A shared CWMP endpoint does not inherently provide cryptographic tenant identity. Hostname/port routing identifies the ingress path, but the application must not assume that a device is owned by a tenant merely because it arrived through a particular endpoint. The implementation must prove that the chosen proxy/gateway can preserve trustworthy ingress context through GenieACS, or use a verifiable enrollment/credential mechanism. If reliable attribution cannot be demonstrated, automatic tenant assignment from ingress alone is prohibited.

## 4. Network boundaries
- Public: tenant CWMP ingress and HTTPS SaaS portal.
- Private: GenieACS NBI, GenieACS UI, MongoDB and MariaDB.
- Admin access: restricted management path, not public tenant access.
- No direct tenant access to NBI, MongoDB or GenieACS UI.

## 5. Failure and scaling
The shared GenieACS service is a common failure and capacity domain. Monitor CPU, memory, swap, disk, MongoDB latency, CWMP session volume, inform rate, NBI latency and queue/backlog indicators. Scale only after baseline measurements. A worker VPS or dedicated ACS plane may be a later architecture evolution, not part of PR #1.

## 6. Existing infrastructure protection
The existing VPS is treated as production infrastructure. PR #1 contains documentation only. Any later infrastructure change requires inventory, backup verification, a change plan, maintenance/rollback plan and explicit owner approval.
