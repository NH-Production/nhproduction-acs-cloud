# Installation guide and scripts

## Important status
The repository currently contains the product foundation and deployment scaffolding. The Go API and frontend build are not yet implemented, so a complete runnable application release bundle does not exist yet. The installer below is for a future pre-built release bundle and must not be mistaken for an application build script.

## Supported installation boundary
- Target: a dedicated Ubuntu/systemd staging host, after a read-only audit.
- Method: native systemd service; no Docker requirement.
- Expected release bundle: `bin/nhacs-api` (executable Go API) and `web/` (built frontend assets).
- Default bind: `127.0.0.1:18080`; not publicly exposed.
- Configuration: `/etc/nhproduction-acs-cloud/app.env`.
- Release path: `/opt/nhproduction-acs-cloud/releases/{version}`.
- Active release: `/opt/nhproduction-acs-cloud/current`.

## 1. Read-only server audit
On the target host, inspect the script first and run:
```bash
bash scripts/preflight.sh
```
It reports host resources, listeners and relevant service status. It does not modify the host. Review the output and check all proposed ports against existing listeners.

## 2. Prepare a release bundle (future build pipeline)
The application build pipeline must eventually produce this structure:
```text
release/
├── bin/
│   └── nhacs-api
└── web/
    └── index.html
```
Package it as a gzip tar archive. Do not create a dummy binary or deploy placeholder code. Build/release tooling will be added alongside the actual Go and frontend implementation.

## 3. Install to staging only
Review the script and confirm the host is a staging target. Example:
```bash
sudo bash scripts/install-staging.sh \
  --environment staging \
  --version 0.1.0-rc1 \
  --bundle ./nhproduction-acs-cloud-0.1.0-rc1.tar.gz \
  --apply
```
This installs files and a systemd unit but does not start the service unless `--start` is also supplied. It does not configure Nginx, DNS, firewall, GenieACS, MongoDB or MariaDB.

Review and edit `/etc/nhproduction-acs-cloud/app.env` using a secure editor. Do not paste secrets into tickets, chat or Git.

Only after a real application binary exists and configuration is validated:
```bash
sudo systemctl start nhproduction-acs-cloud
sudo systemctl status nhproduction-acs-cloud --no-pager
journalctl -u nhproduction-acs-cloud -n 100 --no-pager
```

## 4. Roll back application code on staging
List available releases:
```bash
ls -1 /opt/nhproduction-acs-cloud/releases/
```
Then explicitly select a known-good version:
```bash
sudo bash scripts/rollback-staging.sh --to 0.1.0-rc1 --apply
```
This switches application code only. It does not reverse database migrations.

## 5. Existing production VPS
Do not run the installer on the current GenieACS VPS as part of PR #1. First complete and review the fresh server audit, verify backups and capacity, and test on an isolated staging host. No script in this repository is automatically executed by CI.
