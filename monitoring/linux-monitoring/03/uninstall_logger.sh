#!/bin/bash

# 1. Удаляем конфиги
sudo rm -f /etc/rsyslog.d/linux_monitoring.conf /etc/logrotate.d/linux_monitoring

# 2. Перезапускаем rsyslog (если конфиг был изменён)
sudo systemctl restart rsyslog

# 3. Удаляем логи
sudo rm -f /var/log/linux_monigtoring.log*

echo "Удаление завершено! Все следы скрипта стёрты."