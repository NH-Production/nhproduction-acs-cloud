#!/usr/bin/env bash
set -Eeuo pipefail

# Read-only host inventory. No package installation or configuration changes.
section() { printf '\n===== %s =====\n' "$1"; }

section "Timestamp"
date -Is

section "Operating system"
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  printf 'PRETTY_NAME=%s\nVERSION_ID=%s\n' "${PRETTY_NAME:-unknown}" "${VERSION_ID:-unknown}"
else
  echo "/etc/os-release unavailable"
fi

section "Kernel and uptime"
uname -a
uptime

section "CPU"
if command -v nproc >/dev/null 2>&1; then nproc; fi
if [[ -r /proc/cpuinfo ]]; then grep -m1 'model name' /proc/cpuinfo || true; fi

section "Memory and swap"
free -h || true
if command -v swapon >/dev/null 2>&1; then swapon --show || true; fi

section "Disk"
df -hT

section "Top memory processes"
ps aux --sort=-%mem | head -15

section "Running services"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --type=service --state=running --no-pager || true
  systemctl --failed --no-pager || true
fi

section "Listening sockets"
if command -v ss >/dev/null 2>&1; then
  ss -lntup || true
else
  echo "ss command unavailable"
fi

section "Relevant versions"
for cmd in nginx mariadb mysql mongod go php; do
  if command -v "$cmd" >/dev/null 2>&1; then
    case "$cmd" in
      nginx) nginx -v 2>&1 || true ;;
      mariadb|mysql) "$cmd" --version 2>&1 | head -1 || true ;;
      mongod) mongod --version 2>/dev/null | head -2 || true ;;
      go) go version || true ;;
      php) php -v 2>/dev/null | head -1 || true ;;
    esac
  else
    printf '%s: not installed/in PATH\n' "$cmd"
  fi
done

section "GenieACS service status"
if command -v systemctl >/dev/null 2>&1; then
  systemctl status genieacs-cwmp genieacs-fs genieacs-nbi genieacs-ui --no-pager 2>&1 || true
fi

section "Selected data directory sizes"
for path in /var/lib/mongodb /var/lib/mysql /var/www/gacs-dashboard /opt/nhproduction-acs-cloud; do
  if [[ -e "$path" ]]; then du -sh "$path" 2>/dev/null || true; fi
done

section "Audit complete"
echo "Read-only inventory finished. Review output locally and redact sensitive infrastructure details before sharing."
