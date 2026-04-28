#!/bin/bash
REPO="https://raw.githubusercontent.com/mylo1998/Mylo/main/TOOLS"

red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'

echo -e "${green}Installing Limit IP VLESS/VMESS/SSH...${NC}"
wget -q -O /etc/xray/limit.sh https://raw.githubusercontent.com/username/limit-ip/main/limit.sh
wget -q -O /usr/bin/limit-ssh https://raw.githubusercontent.com/username/limit-ip/main/limit-ssh.sh
chmod +x /etc/xray/limit.sh /usr/bin/limit-ssh

cat > /etc/systemd/system/limitvless.service << EOF
[Unit]
Description=Limit IP Xray Service
After=network.target

[Service]
ExecStart=/etc/xray/limit.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/limitssh.service << EOF
[Unit]
Description=Limit IP SSH Service
After=network.target

[Service]
ExecStart=/usr/bin/limit-ssh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable limitvless limitssh
systemctl restart limitvless limitssh
echo -e "${green}Done! Check: systemctl status limitvless${NC}"
