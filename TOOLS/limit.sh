#!/bin/bash
LOG="/var/log/xray/access.log"
CONFIG="/etc/xray/config.json"
API="127.0.0.1:10085"
LIMIT_LOG="/var/log/limitvless.log"

while true; do
    > /tmp/ip.tmp
    waktu=$(date -d '2 minutes ago' '+%Y/%m/%d %H:%M')
    grep "$waktu" $LOG 2>/dev/null | grep "email:" | while read -r line; do
        email=$(echo "$line" | awk -F'email: ' '{print $2}' | awk '{print $1}')
        ip=$(echo "$line" | awk '{print $3}' | cut -d: -f1)
        [[ -n $email && -n $ip ]] && echo "$email $ip" >> /tmp/ip.tmp
    done
    if [[ -s /tmp/ip.tmp ]]; then
        for user in $(awk '{print $1}' /tmp/ip.tmp | sort -u); do
            limit=$(grep "^[[:space:]]*// #! $user " $CONFIG | awk '{print $5}')
            [[ -z $limit ]] && continue
            ip_count=$(grep "^$user " /tmp/ip.tmp | awk '{print $2}' | sort -u | wc -l)
            if [[ $ip_count -gt $limit ]]; then
                ip_list=$(grep "^$user " /tmp/ip.tmp | awk '{print $2}' | sort -u | tr '\n' ' ')
                echo "$(date '+%F %T') - $user over limit $ip_count/$limit | IP: $ip_list" >> $LIMIT_LOG
                xray api adu -s $API "email: $user"
            fi
        done
    fi
    sleep 60
done