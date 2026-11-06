#!/usr/bin/env bash
set -Eeuo pipefail

# Installs a PRE-BUILT application bundle to an isolated staging path.
# It does not provision OS packages, edit Nginx/DNS/firewall, or touch GenieACS/MongoDB.
# Usage:
#   sudo bash scripts/install-staging.sh --environment staging --version 0.1.0 --bundle /path/to/release.tar.gz --apply
# Add --start only after the bundle and environment configuration have been reviewed.

ENVIRONMENT=""
VERSION=""
BUNDLE=""
APPLY=0
START=0
APP_ROOT="/opt/nhproduction-acs-cloud"
CONFIG_DIR="/etc/nhproduction-acs-cloud"
SERVICE="nhproduction-acs-cloud"
RUN_USER="nhacs"
HTTP_ADDR="127.0.0.1:18080"

die() { echo "ERROR: $*" >&2; exit 1; }
log() { echo "[$(date -Is)] $*"; }

while (($#)); do
  case "$1" in
    --environment) ENVIRONMENT="${2:-}"; shift 2 ;;
    --version) VERSION="${2:-}"; shift 2 ;;
    --bundle) BUNDLE="${2:-}"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --start) START=1; shift ;;
    --help|-h)
      sed -n '1,18p' "$0"
      exit 0
      ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ "$ENVIRONMENT" == "staging" ]] || die "Only --environment staging is permitted by this installer."
[[ "$APPLY" -eq 1 ]] || die "No changes made. Pass --apply after reviewing this script and the staging host."
[[ "$VERSION" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || die "Invalid --version."
[[ -n "$BUNDLE" && -f "$BUNDLE" ]] || die "A readable --bundle release archive is required."
[[ $EUID -eq 0 ]] || die "Run with sudo/root on a dedicated staging host."
command -v tar >/dev/null 2>&1 || die "tar is required."
command -v ss >/dev/null 2>&1 || die "iproute2/ss is required."
command -v systemctl >/dev/null 2>&1 || die "systemd is required."

# Refuse accidental installation over an existing application path.
RELEASE_DIR="$APP_ROOT/releases/$VERSION"
[[ ! -e "$RELEASE_DIR" ]] || die "Release already exists: $RELEASE_DIR"
if ss -ltnH 2>/dev/null | awk '{print $4}' | grep -Eq '(^|:)18080$'; then
  die "TCP port 18080 is already listening. Resolve the conflict before installing."
fi

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

tar -tzf "$BUNDLE" >/dev/null || die "Bundle is not a valid gzip tar archive."
tar -xzf "$BUNDLE" -C "$TMP_DIR"
[[ -x "$TMP_DIR/bin/nhacs-api" ]] || die "Bundle must contain executable bin/nhacs-api."
[[ -d "$TMP_DIR/web" ]] || die "Bundle must contain web/ directory (built frontend assets)."

log "Validated release bundle $VERSION"
if [[ "$START" -eq 1 ]]; then
  [[ -f "$CONFIG_DIR/app.env" ]] || die "Missing $CONFIG_DIR/app.env. Configure secrets and database settings before --start."
fi

install -d -m 0755 "$APP_ROOT/releases" "$CONFIG_DIR"
if ! id "$RUN_USER" >/dev/null 2>&1; then
  useradd --system --home-dir "$APP_ROOT" --shell /usr/sbin/nologin "$RUN_USER"
fi

install -d -m 0755 "$RELEASE_DIR"
cp -a "$TMP_DIR/." "$RELEASE_DIR/"
chown -R root:"$RUN_USER" "$RELEASE_DIR"
chmod -R o-rwx "$RELEASE_DIR"
chmod 0750 "$RELEASE_DIR/bin/nhacs-api"

if [[ ! -f "$CONFIG_DIR/app.env" ]]; then
  install -m 0640 -o root -g "$RUN_USER" "$(dirname "$0")/../deploy/app.env.example" "$CONFIG_DIR/app.env"
  log "Created non-secret configuration template at $CONFIG_DIR/app.env; edit it before starting the service."
fi
chown root:"$RUN_USER" "$CONFIG_DIR/app.env"
chmod 0640 "$CONFIG_DIR/app.env"

UNIT_TMP="$(mktemp)"
cat > "$UNIT_TMP" <<EOF
[Unit]
Description=NHProduction ACS Cloud API (staging)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$RUN_USER
Group=$RUN_USER
WorkingDirectory=$APP_ROOT/current
EnvironmentFile=$CONFIG_DIR/app.env
ExecStart=$APP_ROOT/current/bin/nhacs-api
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_ROOT/shared
UMask=0027

[Install]
WantedBy=multi-user.target
EOF
install -m 0644 "$UNIT_TMP" "/etc/systemd/system/$SERVICE.service"
rm -f "$UNIT_TMP"

install -d -o "$RUN_USER" -g "$RUN_USER" -m 0750 "$APP_ROOT/shared"
if [[ -L "$APP_ROOT/current" ]]; then
  ln -sfn "$RELEASE_DIR" "$APP_ROOT/current"
elif [[ -e "$APP_ROOT/current" ]]; then
  die "$APP_ROOT/current exists and is not a symlink; refusing to replace it."
else
  ln -s "$RELEASE_DIR" "$APP_ROOT/current"
fi

systemctl daemon-reload
if [[ "$START" -eq 1 ]]; then
  systemctl enable --now "$SERVICE.service"
  systemctl --no-pager --full status "$SERVICE.service" || true
else
  log "Installed files and systemd unit. Service was NOT started."
  log "Review $CONFIG_DIR/app.env, then run: sudo systemctl start $SERVICE"
fi

log "Staging installation completed. No Nginx, DNS, firewall, GenieACS, MongoDB or MariaDB settings were changed."
