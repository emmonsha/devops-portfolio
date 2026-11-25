#!/usr/bin/env bash

output_file="/var/www/html/metrics"

touch "$output_file"
chmod 644 "$output_file"

while true; do
    # CPU (%)
    cpu_used=$(top -bn1 | awk 'NR==3{printf $2}')

    # Память (GB)
    mem_free_mb=$(free -b | awk 'NR==2{printf "%.1f", $4/1048576}')

    # Диск (GB) 
    read _ disk_total disk_used disk_free _ < <(df -B1 / | awk 'NR==2')

    disk_total_gb=$(echo "$disk_total" | awk '{printf "%.2f", $1/1073741824}')
    disk_used_gb=$(echo "$disk_used" | awk '{printf "%.2f", $1/1073741824}')
    disk_free_gb=$(echo "$disk_free" | awk '{printf "%.2f", $1/1073741824}')


    # IOPS
    disk_stats_line=$(grep 'sda ' /proc/diskstats)
    iops_read=$(echo "$disk_stats_line" | awk '{print $4}')
    iops_write=$(echo "$disk_stats_line" | awk '{print $8}')

    # Формируем метрики
    cat <<EOF > "$output_file"
    # HELP emmonsha_cpu_used CPU usage in percent
    # TYPE emmonsha_cpu_used gauge
    emmonsha_cpu_used $cpu_used

    # HELP emmonsha_mem_free Free memory in MB
    # TYPE emmonsha_mem_free gauge
    emmonsha_mem_free $mem_free_mb

    # HELP emmonsha_disk_total Total disk space in MB
    # TYPE emmonsha_disk_total gauge
    emmonsha_disk_total $disk_total_gb

    # HELP emmonsha_disk_used Used disk space in MB
    # TYPE emmonsha_disk_used gauge
    emmonsha_disk_used $disk_used_gb

    # HELP emmonsha_disk_free Free disk space in MB
    # TYPE emmonsha_disk_free gauge
    emmonsha_disk_free $disk_free_gb

    # HELP emmonsha_iops_read Disk read operations (total)
    # TYPE emmonsha_iops_read counter
    emmonsha_iops_read $iops_read

    # HELP emmonsha_iops_write Disk write operations (total)
    # TYPE emmonsha_iops_write counter
    emmonsha_iops_write $iops_write
    EOF

    sleep 3
done
