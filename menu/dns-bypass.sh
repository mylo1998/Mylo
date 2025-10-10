#!/bin/bash

# A script to configure systemd-resolved for encrypted DNS
# It configures the system to use Quad9 for encrypted DNS over TLS (DoT)

# Check if the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Create a backup of the original resolved.conf file
echo "Creating a backup of /etc/systemd/resolved.conf to /etc/systemd/resolved.conf.bak"
cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak

# Update the systemd-resolved configuration
echo "Configuring systemd-resolved for DNS over TLS with Quad9..."
cat << EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net
DNSOverTLS=yes
Domains=~.
EOF

# Restart systemd-resolved to apply changes
echo "Restarting systemd-resolved service..."
systemctl restart systemd-resolved

# Verify the changes
echo "Verifying DNS settings..."
resolvectl status | grep 'DNS Server' -A4

echo "Script complete. Your system is now using encrypted DNS."