# Tenant subdomain and port allocation

## Naming
Parent domain: `network-nh.cloud`.
Tenant ACS host pattern: `{tenant-slug}.acs.network-nh.cloud`.

Examples:
| Tenant | Hostname | TCP ingress port |
|---|---|---:|
| isp-a | isp-a.acs.network-nh.cloud | 17547 |
| isp-b | isp-b.acs.network-nh.cloud | 17548 |
| isp-c | isp-c.acs.network-nh.cloud | 17549 |
| isp-d | isp-d.acs.network-nh.cloud | 17550 |
| isp-e | isp-e.acs.network-nh.cloud | 17551 |

These are proposed allocations only. No DNS records, listeners or firewall rules have been created.

## Allocation rules
- Start at the configured base port 17547 and increment by one for each new tenant.
- Store allocation in the database with a unique constraint on port and hostname.
- Allocation must be transactional; concurrent tenant creation cannot receive the same port.
- Never recycle a port immediately after tenant deletion; mark it reserved/released and apply an explicit cooldown/review policy.
- Validate the selected range against the live server inventory before any deployment.
- Keep NBI, UI and database ports separate and private; tenant ingress ports must not expose those services.

## Routing and DNS
Each tenant hostname resolves to the existing VPS public address. Gateway routing maps hostname/port to the one shared CWMP upstream. TLS and certificate strategy must be validated against CPE compatibility and CWMP transport requirements. The exact proxy implementation is an engineering decision gated by protocol testing; generic HTTP virtual-host routing must not be assumed to support every CWMP transport arrangement.

## Conflict and failure behavior
- Port/hostname conflict: reject allocation and report a safe administrative error.
- Unknown hostname or port: reject; never route to a default tenant.
- Disabled tenant: reject new tenant provisioning/portal actions according to policy.
- Gateway unavailable: fail closed; do not bypass gateway and expose internal services.
