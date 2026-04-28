#!/bin/bash

LIMIT_LOG="/var/log/limitssh.log"
while true; do
    for user in $(who | awk '{print $1}' | sort -u); do
        limit=$(grep "^$user - maxlogins" /etc/security/limits.conf | awk '{print $4}')
        [[ -z $limit ]] && continue
        ip_count=$(who | grep "^$user " | awk '{print $5}' | tr -d '()' | sort -u | wc -l)
        if [[ $ip_count -gt $limit ]]; then
            pkill -KILL -u $user
            echo "$(date '+%F %T') - $user over limit $ip_count/$limit" >> $LIMIT_LOG
        fi
    done
    sleep 30
done
