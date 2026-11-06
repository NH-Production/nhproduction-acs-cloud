#!/usr/bin/env bash
set -Eeuo pipefail

APP_ROOT="/opt/nhproduction-acs-cloud"
SERVICE="nhproduction-acs-cloud"
APPLY=0
TARGET=""

while (($#)); do
  case "$1" in
    --to) TARGET="${2:-}"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --help|-h)
      echo "Usage: sudo bash scripts/rollback-staging.sh --to VERSION --apply"
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 1; }
[[ "$APPLY" -eq 1 ]] || { echo "No changes made. Pass --apply to confirm rollback." >&2; exit 1; }
[[ "$TARGET" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || { echo "Invalid --to version." >&2; exit 1; }
[[ -x "$APP_ROOT/releases/$TARGET/bin/nhacs-api" ]] || { echo "Target release not found." >&2; exit 1; }

systemctl stop "$SERVICE.service" 2>/dev/null || true
ln -sfn "$APP_ROOT/releases/$TARGET" "$APP_ROOT/current"
systemctl start "$SERVICE.service"
systemctl --no-pager --full status "$SERVICE.service"
echo "Rollback switched application code to $TARGET. Database migrations are NOT automatically rolled back."
