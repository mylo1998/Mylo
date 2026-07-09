#!/bin/bash
set -e

# ==========================================
# Xray VLESS + VMess IP LIMIT
# Auto Install Script
# ==========================================

GREEN="\033[0;32m"
NC="\033[0m"

echo -e "${GREEN}Installing Xray VLESS + VMess IP Limit...${NC}"


# Check root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi


# Check Xray log
mkdir -p /etc/xray


# ==========================================
# CREATE LIMIT SCRIPT
# ==========================================

cat > /usr/local/bin/xray-limit-ip <<'EOF'
#!/bin/bash

LOG="/var/log/xray/access.log"
DB="/etc/xray/limit-ip.db"

mkdir -p /etc/xray
touch $DB


while true
do

if [ ! -f "$LOG" ]; then
    sleep 10
    continue
fi


tail -Fn0 "$LOG" | while read line
do

UUID=$(echo "$line" | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F-]{27,}' | head -1)

IP=$(echo "$line" | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | head -1)


if [[ -n "$UUID" ]] && [[ -n "$IP" ]]
then

OLD_IP=$(grep "^$UUID " $DB | awk '{print $2}')


# First login
if [[ -z "$OLD_IP" ]]
then

echo "$UUID $IP" >> $DB

echo "$(date) ALLOW $UUID $IP"


# Different IP detected
elif [[ "$OLD_IP" != "$IP" ]]
then

echo "$(date) BLOCK $UUID $IP"


# Add firewall block
iptables -C INPUT -s "$IP" -j DROP 2>/dev/null

if [ $? -ne 0 ]
then
    iptables -I INPUT -s "$IP" -j DROP
fi


fi


fi

done

done
EOF


chmod +x /usr/local/bin/xray-limit-ip



# ==========================================
# CREATE SYSTEMD SERVICE
# ==========================================

cat > /etc/systemd/system/xray-limit-ip.service <<EOF
[Unit]
Description=Xray VLESS VMess IP Limit
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/xray-limit-ip
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF



# ==========================================
# START SERVICE
# ==========================================

systemctl daemon-reload

systemctl enable xray-limit-ip

systemctl restart xray-limit-ip



echo ""
echo "================================="
echo " Xray VLESS + VMess LIMIT READY "
echo "================================="
echo ""
echo "Status:"
echo "systemctl status xray-limit-ip"
echo ""
echo "Log:"
echo "journalctl -u xray-limit-ip -f"
echo ""
echo "Database:"
echo "/etc/xray/limit-ip.db"