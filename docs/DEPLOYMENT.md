# Deployment and operations policy

## Current phase
Documentation and repository foundation only. No deployment is authorized.

## Existing VPS preservation
Do not install packages, change DNS, open ports, edit Nginx, restart services, modify GenieACS, or migrate databases as part of PR #1. First collect a read-only inventory and verify backups.

## Future deployment prerequisites
1. Owner-approved server audit and capacity assessment.
2. Verified backup of application files and databases, plus tested restoration procedure.
3. Confirmed DNS, TLS and CWMP gateway compatibility.
4. Port-range conflict check against all existing listeners and firewall rules.
5. Staging deployment isolated from production.
6. Automated tests, security tests and load tests with representative device behavior.
7. Maintenance window, rollback plan and explicit owner approval.

## Operational monitoring
Track host CPU/RAM/swap/disk, MongoDB health/latency, GenieACS CWMP and NBI health, connection/inform rates, gateway errors, API latency, queue depth, tenant quota and backup freshness.

## Rollback
Rollback must restore the prior application/configuration and compatible database state. Never delete or overwrite GenieACS MongoDB data as a rollback shortcut. Any schema migration needs a reviewed forward/rollback strategy and a pre-change backup.
