#!/usr/bin/env bash
set -Eeuo pipefail

# Staging-only installer for a PRE-BUILT application bundle.
# Does not provision packages, change Nginx/DNS/firewall, or touch GenieACS/DB services.
# Usage:
# sudo bash scripts/install-staging.sh --environment staging --version 0.1.0 --bundle ./release.tar.gz --apply
# Add --start only after configuring and reviewing /etc/nhproduction-acs-cloud/app.env.

ENVIRONMENT="" VERSION="" BUNDLE="" APPLY=0 START=0
APP_ROOT="/opt/nhproduction-acs-cloud"
CONFIG_DIR="/etc/nhproduction-acs-cloud"
SERVICE="nhproduction-acs-cloud"
RUN_USER="nhacs"
die() { echo "ERROR: $*" >&2; exit 1; }
log() { echo "[$(date -Is)] $*"; }

while (($#)); do
  case "$1" in
    --environment) [[ $# -ge 2 ]] || die "Missing value for $1"; ENVIRONMENT="$2"; shift 2 ;;
    --version) [[ $# -ge 2 ]] || die "Missing value for $1"; VERSION="$2"; shift 2 ;;
    --bundle) [[ $# -ge 2 ]] || die "Missing value for $1"; BUNDLE="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --start) START=1; shift ;;
    --help|-h) echo "Usage: sudo bash $0 --environment staging --version VERSION --bundle FILE.tar.gz --apply [--start]"; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ "$ENVIRONMENT" == "staging" ]] || die "Only --environment staging is permitted."
[[ "$APPLY" -eq 1 ]] || die "No changes made. Pass --apply after reviewing the staging host."
[[ "$VERSION" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || die "Invalid version."
[[ -n "$BUNDLE" && -f "$BUNDLE" && -r "$BUNDLE" ]] || die "Readable --bundle archive required."
[[ $EUID -eq 0 ]] || die "Run as root on a dedicated staging host."
for cmd in tar ss systemctl install useradd; do command -v "$cmd" >/dev/null 2>&1 || die "$cmd is required."; done

RELEASE_DIR="$APP_ROOT/releases/$VERSION"
[[ ! -e "$RELEASE_DIR" ]] || die "Release already exists: $RELEASE_DIR"
[[ ! -e "$APP_ROOT/current" || -L "$APP_ROOT/current" ]] || die "$APP_ROOT/current exists and is not a symlink."
[[ ! -e "/etc/systemd/system/$SERVICE.service" ]] || die "Service unit already exists; refusing to overwrite it."
if ss -ltnH 2>/dev/null | awk '{print $4}' | grep -Eq '(^|:)18080$'; then
  die "TCP port 18080 is already listening."
fi
if [[ "$START" -eq 1 && ! -f "$CONFIG_DIR/app.env" ]]; then
  die "Configure $CONFIG_DIR/app.env before requesting --start."
fi

TMP_DIR="$(mktemp -d)"
UNIT_TMP=""
cleanup() { rm -rf "$TMP_DIR"; [[ -z "$UNIT_TMP" ]] || rm -f "$UNIT_TMP"; }
trap cleanup EXIT

tar -tzf "$BUNDLE" >/dev/null || die "Invalid gzip tar archive."
# Reject absolute paths and parent traversal before extraction.
while IFS= read -r member; do
  [[ "$member" != /* ]] || die "Archive contains an absolute path."
  case "/$member/" in */../*) die "Archive contains parent-directory traversal." ;; esac
done < <(tar -tzf "$BUNDLE")
tar --no-same-owner --no-same-permissions -xzf "$BUNDLE" -C "$TMP_DIR"
[[ -x "$TMP_DIR/bin/nhacs-api" ]] || die "Bundle must contain executable bin/nhacs-api."
[[ -d "$TMP_DIR/web" ]] || die "Bundle must contain built web/ assets."

log "Validated release bundle $VERSION."
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
  SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
  EXAMPLE="$SCRIPT_DIR/../deploy/app.env.example"
  [[ -f "$EXAMPLE" ]] || die "Missing config template: $EXAMPLE"
  install -m 0640 -o root -g "$RUN_USER" "$EXAMPLE" "$CONFIG_DIR/app.env"
  log "Created configuration template; edit it securely before starting."
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
UNIT_TMP=""

install -d -o "$RUN_USER" -g "$RUN_USER" -m 0750 "$APP_ROOT/shared"
if [[ -L "$APP_ROOT/current" ]]; then
  ln -sfn "$RELEASE_DIR" "$APP_ROOT/current"
else
  ln -s "$RELEASE_DIR" "$APP_ROOT/current"
fi

systemctl daemon-reload
if [[ "$START" -eq 1 ]]; then
  systemctl enable --now "$SERVICE.service"
  systemctl --no-pager --full status "$SERVICE.service"
else
  log "Files and unit installed; service NOT started. Review $CONFIG_DIR/app.env first."
fi
log "Staging install completed. No Nginx, DNS, firewall, GenieACS, MongoDB or MariaDB settings changed."
