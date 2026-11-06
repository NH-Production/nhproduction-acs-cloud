#!/usr/bin/env bash
set -Eeuo pipefail

# Safe foundation bootstrap only. Dry-run by default.
APPLY=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h|--help)
      echo "Usage: sudo bash scripts/install-foundation.sh [--apply]"
      echo "Default is dry-run. --apply creates a system user, directories, env template and disabled systemd unit."
      exit 0
      ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

APP_NAME="nhproduction-acs-cloud"
APP_USER="nhpacs"
APP_GROUP="nhpacs"
APP_DIR="/opt/$APP_NAME"
CONFIG_DIR="/etc/$APP_NAME"
ENV_FILE="$CONFIG_DIR/app.env"
UNIT_FILE="/etc/systemd/system/$APP_NAME.service"
BINARY="$APP_DIR/bin/$APP_NAME"
LISTEN_PORT="18088"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo/root." >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot identify operating system; refusing." >&2
  exit 1
fi
. /etc/os-release
if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "22.04" ]]; then
  echo "This initial script supports Ubuntu 22.04 only; detected ${PRETTY_NAME:-unknown}." >&2
  exit 1
fi

# Refuse to collide with pre-existing files or directories.
for path in "$APP_DIR" "$CONFIG_DIR" "$ENV_FILE" "$UNIT_FILE"; do
  if [[ -e "$path" ]]; then
    echo "Refusing to overwrite existing path: $path" >&2
    exit 1
  fi
done

# Check the future default application port is not already listening.
if command -v ss >/dev/null 2>&1 && ss -lntH "( sport = :$LISTEN_PORT )" | grep -q .; then
  echo "TCP port $LISTEN_PORT is already in use; choose another port after review." >&2
  exit 1
fi

actions=(
  "Create system group $APP_GROUP"
  "Create non-login system user $APP_USER"
  "Create $APP_DIR/{bin, releases, shared}"
  "Create $CONFIG_DIR and a restrictive app.env template"
  "Create disabled systemd unit $APP_NAME.service"
  "Run systemctl daemon-reload (unit remains disabled and stopped)"
)
printf 'Planned foundation actions:\n'
printf ' - %s\n' "${actions[@]}"
echo
echo "No packages, GenieACS settings, databases, Nginx, DNS or firewall rules will be changed."

if [[ $APPLY -ne 1 ]]; then
  echo "DRY RUN ONLY. Re-run with --apply on a clean staging host to create these paths."
  exit 0
fi

if getent group "$APP_GROUP" >/dev/null 2>&1; then
  echo "Group $APP_GROUP already exists; refusing to adopt an unverified account." >&2
  exit 1
fi
if id "$APP_USER" >/dev/null 2>&1; then
  echo "User $APP_USER already exists; refusing to adopt an unverified account." >&2
  exit 1
fi

groupadd --system "$APP_GROUP"
useradd --system --gid "$APP_GROUP" --home-dir "$APP_DIR" --shell /usr/sbin/nologin "$APP_USER"
install -d -o root -g "$APP_GROUP" -m 0750 "$APP_DIR"
install -d -o "$APP_USER" -g "$APP_GROUP" -m 0750 "$APP_DIR/bin" "$APP_DIR/releases" "$APP_DIR/shared"
install -d -o root -g "$APP_GROUP" -m 0750 "$CONFIG_DIR"

cat > "$ENV_FILE" <<'ENV'
# Replace placeholders only through an approved secure configuration process.
APP_ENV=staging
APP_LISTEN_ADDR=127.0.0.1:18088
APP_LOG_LEVEL=info
# DATABASE_DSN=configure-out-of-band
# SESSION_SECRET=configure-out-of-band
ENV
chown root:"$APP_GROUP" "$ENV_FILE"
chmod 0640 "$ENV_FILE"

cat > "$UNIT_FILE" <<UNIT
[Unit]
Description=NHProduction ACS Cloud API
After=network.target
Wants=network.target

[Service]
Type=simple
User=$APP_USER
Group=$APP_GROUP
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$BINARY
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR/shared
UMask=0027

[Install]
WantedBy=multi-user.target
UNIT
chmod 0644 "$UNIT_FILE"
systemctl daemon-reload

echo
echo "Foundation directories and disabled unit created."
echo "Service was NOT enabled or started. No application binary is installed."
echo "Next: review $ENV_FILE, build a signed/reviewed application release, then follow docs/INSTALLATION.md."
