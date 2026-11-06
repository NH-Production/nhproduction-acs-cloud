#!/usr/bin/env bash
set -Eeuo pipefail

# Read-only inventory. This script does not install, stop, restart, or configure services.
section() { printf '\n==== %s ====\n' "$1"; }

section "Host"
date -Is
hostnamectl 2>/dev/null || true
uname -a
uptime

section "Resources"
free -h
swapon --show
df -hT

section "CPU"
nproc
lscpu 2>/dev/null | grep -E '^(Architecture|CPU\(s\)|Model name|Thread|Core|Socket):' || true

section "Listening TCP/UDP sockets"
ss -lntup 2>/dev/null || true

section "Relevant services"
for unit in nginx genieacs-cwmp genieacs-fs genieacs-nbi genieacs-ui mongod mariadb mysql; do
  if systemctl list-unit-files "${unit}.service" --no-legend 2>/dev/null | grep -q "${unit}.service"; then
    printf '\n-- %s --\n' "$unit"
    systemctl is-active "$unit" 2>/dev/null || true
    systemctl is-enabled "$unit" 2>/dev/null || true
  fi
done

section "Versions"
for cmd in nginx mongod mongosh mariadb mysql go php node npm; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '%s: ' "$cmd"
    case "$cmd" in
      nginx) nginx -v 2>&1 ;;
      mongod) mongod --version 2>/dev/null | head -1 ;;
      mongosh) mongosh --version 2>/dev/null | head -1 ;;
      mariadb|mysql) "$cmd" --version 2>/dev/null | head -1 ;;
      go) go version ;;
      php) php -v 2>/dev/null | head -1 ;;
      node) node --version ;;
      npm) npm --version ;;
    esac
  fi
done

section "GenieACS data directories (metadata only)"
for path in /var/lib/mongodb /var/lib/mysql /var/www/gacs-dashboard /opt/genieacs; do
  if [ -e "$path" ]; then du -sh "$path" 2>/dev/null || true; fi
done

printf '\nAudit complete. Review output before planning any change. Do not share secrets or environment-file contents.\n'
