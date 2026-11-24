
#!/usr/bin/env bash
# ==========================================
# FIX MISSING XRAY GEOSITE.DAT
# Repository: mylo1998/Mylo
# ==========================================

set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Sila jalankan sebagai root."
    exit 1
fi

echo "================================"
echo "       XRAY GEOSITE FIX"
echo "================================"

XRAY_BIN="$(command -v xray || true)"

if [[ -z "$XRAY_BIN" ]]; then
    echo "ERROR: Xray tidak dijumpai."
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    apt-get update
    apt-get install -y curl
fi

DEST="/usr/local/bin/geosite.dat"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

URLS=(
    "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
    "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat"
)

DOWNLOADED=0

for URL in "${URLS[@]}"; do
    echo "Downloading geosite.dat..."

    if curl -fL --connect-timeout 15 --max-time 180 "$URL" -o "$TMP" &&
       [[ -s "$TMP" ]]; then
        DOWNLOADED=1
        break
    fi
done

if [[ "$DOWNLOADED" -ne 1 ]]; then
    echo "ERROR: Gagal download geosite.dat."
    exit 1
fi

install -m 0644 "$TMP" "$DEST"

echo "geosite.dat dipasang di $DEST"

CONFIG="/etc/xray/config.json"

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: Config Xray tidak dijumpai."
    exit 1
fi

echo "Menguji konfigurasi Xray..."

if "$XRAY_BIN" run -test -config "$CONFIG"; then
    echo "Config OK. Restart Xray..."
    systemctl restart xray
    systemctl --no-pager --full status xray
else
    echo "ERROR: Config masih mempunyai masalah."
    echo "Xray tidak direstart."
    exit 1
fi

echo "================================"
echo "       SELESAI"
echo "================================"
