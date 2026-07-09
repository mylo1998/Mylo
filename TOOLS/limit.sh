#!/bin/bash

REPO="https://raw.githubusercontent.com/mylo1998/Mylo/refs/heads/main/"

# Download limit service
wget -q -O /etc/systemd/system/limitvmess.service "${REPO}TOOLS/limitvmess.service" || exit 1
wget -q -O /etc/systemd/system/limitvless.service "${REPO}TOOLS/limitvless.service" || exit 1
wget -q -O /etc/systemd/system/limittrojan.service "${REPO}TOOLS/limittrojan.service" || exit 1
wget -q -O /etc/systemd/system/limitshadowsocks.service "${REPO}TOOLS/limitshadowsocks.service" || exit 1

chmod +x /etc/systemd/system/*.service


# Download limit binary
wget -q -O /etc/xray/limit.vmess "${REPO}bin/vmess" || exit 1
wget -q -O /etc/xray/limit.vless "${REPO}bin/vless" || exit 1
wget -q -O /etc/xray/limit.trojan "${REPO}bin/trojan" || exit 1
wget -q -O /etc/xray/limit.shadowsocks "${REPO}bin/shadowsocks" || exit 1

chmod +x /etc/xray/limit.vmess
chmod +x /etc/xray/limit.vless
chmod +x /etc/xray/limit.trojan
chmod +x /etc/xray/limit.shadowsocks


systemctl daemon-reload

systemctl enable --now limitvmess
systemctl enable --now limitvless
systemctl enable --now limittrojan
systemctl enable --now limitshadowsocks


# Download limit-ip
wget -q -O /usr/bin/limit-ip "${REPO}files/limit-ip" || exit 1

chmod +x /usr/bin/limit-ip

sed -i 's/\r$//' /usr/bin/limit-ip


# VMESS IP LIMIT
cat >/etc/systemd/system/vmip.service <<EOF
[Unit]
Description=VMESS IP Limit
After=network.target

[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/limit-ip vmip
Restart=always

[Install]
WantedBy=multi-user.target
EOF


# VLESS IP LIMIT
cat >/etc/systemd/system/vlip.service <<EOF
[Unit]
Description=VLESS IP Limit
After=network.target

[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/limit-ip vlip
Restart=always

[Install]
WantedBy=multi-user.target
EOF


# TROJAN IP LIMIT
cat >/etc/systemd/system/trip.service <<EOF
[Unit]
Description=TROJAN IP Limit
After=network.target

[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/limit-ip trip
Restart=always

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload


systemctl enable vmip
systemctl restart vmip

systemctl enable vlip
systemctl restart vlip

systemctl enable trip
systemctl restart trip


rm -rf /root/fv-tunnel