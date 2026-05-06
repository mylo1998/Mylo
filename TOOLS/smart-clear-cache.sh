#!/bin/bash

# Limit penggunaan RAM (%) sebelum clear
LIMIT=80

# Ambil usage RAM semasa
RAM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

# Convert ke integer
RAM_INT=${RAM_USAGE%.*}

# Log file
LOG="/var/log/ram_cleaner.log"

echo "[$(date)] RAM Usage: $RAM_INT%" >> $LOG

# Check kalau lebih limit
if [ "$RAM_INT" -ge "$LIMIT" ]; then
    echo "[$(date)] High RAM detected. Clearing cache..." >> $LOG
    
    sync
    echo 1 > /proc/sys/vm/drop_caches
    echo 2 > /proc/sys/vm/drop_caches
    echo 3 > /proc/sys/vm/drop_caches

    echo "[$(date)] Cache cleared!" >> $LOG
else
    echo "[$(date)] RAM normal. No action." >> $LOG
fi