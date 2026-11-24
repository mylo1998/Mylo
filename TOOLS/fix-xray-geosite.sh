#!/usr/bin/env bash
# ==========================================================
# MYLO VPS - Xray Repair
# Repairs Xray log permissions and missing geosite.dat/geoip.dat
# Does NOT modify Nginx or /etc/xray/config.json
# ==========================================================

set -Eeuo pipefail

CONFIG="/etc/xray/config.json"
XRAY_BIN="/usr/local/bin/xray"
GEO_DIR="/usr/local/bin"
LOG_DIR="/var/log/xray"
SOURCE_BASE="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download"

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: Run this script as root."
    exit 1
fi

if [[ ! -x "$XRAY_BIN" ]]; then
    XRAY_BIN="$(command -v xray || true)"
fi

if [[ -z "$XRAY_BIN" || ! -x "$XRAY_BIN" ]]; then
    echo "ERROR: Xray binary was not found."
    exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: Xray config not found: $CONFIG"
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    apt-get update
    apt-get install -y curl
fi

SERVICE_USER="$(systemctl show xray -p User --value 2>/dev/null || true)"
if [[ -z "$SERVICE_USER" ]]; then
    SERVICE_USER="root"
fi

if ! id "$SERVICE_USER" >/dev/null 2>&1; then
    echo "ERROR: Xray service user '$SERVICE_USER' does not exist."
    exit 1
fi

SERVICE_GROUP="$(id -gn "$SERVICE_USER")"

TMP_DIR="$(mktemp -d)"
BACKUP_DIR="$TMP_DIR/backup"
mkdir -p "$BACKUP_DIR"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "=========================================="
echo "          MYLO VPS - XRAY REPAIR"
echo "=========================================="
echo "Xray binary : $XRAY_BIN"
echo "Service user: $SERVICE_USER:$SERVICE_GROUP"
echo

# Download both data files before changing the installed copies.
for DATA_FILE in geosite.dat geoip.dat; do
    echo "Downloading $DATA_FILE ..."
    if ! curl -fL --retry 2 --connect-timeout 15 --max-time 240 \
        "$SOURCE_BASE/$DATA_FILE" -o "$TMP_DIR/$DATA_FILE"; then
        echo "ERROR: Could not download $DATA_FILE. Nothing was installed."
        exit 1
    fi

    if [[ ! -s "$TMP_DIR/$DATA_FILE" ]]; then
        echo "ERROR: Downloaded $DATA_FILE is empty. Nothing was installed."
        exit 1
    fi
done

# Back up any existing data files so they can be restored if config test fails.
for DATA_FILE in geosite.dat geoip.dat; do
    if [[ -f "$GEO_DIR/$DATA_FILE" ]]; then
        cp -a "$GEO_DIR/$DATA_FILE" "$BACKUP_DIR/$DATA_FILE"
        touch "$BACKUP_DIR/${DATA_FILE}.was_present"
    fi
done

install -m 0644 "$TMP_DIR/geosite.dat" "$GEO_DIR/geosite.dat"
install -m 0644 "$TMP_DIR/geoip.dat" "$GEO_DIR/geoip.dat"

# Repair the log directory and files used by this VPS configuration.
install -d -o "$SERVICE_USER" -g "$SERVICE_GROUP" -m 0755 "$LOG_DIR"
for LOG_FILE in access.log error.log; do
    touch "$LOG_DIR/$LOG_FILE"
    chown "$SERVICE_USER:$SERVICE_GROUP" "$LOG_DIR/$LOG_FILE"
    chmod 0644 "$LOG_DIR/$LOG_FILE"
done

echo
echo "Testing Xray configuration..."
if ! "$XRAY_BIN" run -test -config "$CONFIG"; then
    echo
    echo "ERROR: Xray configuration test failed."
    echo "Restoring previous geodata files..."

    for DATA_FILE in geosite.dat geoip.dat; do
        if [[ -f "$BACKUP_DIR/${DATA_FILE}.was_present" ]]; then
            cp -a "$BACKUP_DIR/$DATA_FILE" "$GEO_DIR/$DATA_FILE"
        else
            rm -f "$GEO_DIR/$DATA_FILE"
        fi
    done

    echo "Xray was NOT restarted. Check the error above."
    exit 1
fi

echo
echo "Configuration OK. Restarting Xray..."
systemctl restart xray
sleep 2

if systemctl is-active --quiet xray; then
    echo
    echo "SUCCESS: Xray is active."
    systemctl --no-pager --full status xray
else
    echo
    echo "ERROR: Xray did not become active."
    echo "Recent service logs:"
    journalctl -u xray -n 30 --no-pager
    exit 1
fi

echo
echo "Repair completed. Nginx and the Xray JSON configuration were not modified."
