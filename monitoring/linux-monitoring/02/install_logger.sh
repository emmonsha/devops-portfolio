#!/usr/bin/env bash

# Запись файла настроек для rsyslog
sudo sh -c 'cat > /etc/rsyslog.d/linux_monitoring.conf' <<'EOF'
# sudo sh -c 'cat > /etc/rsyslog.d/linux_monitoring.conf' <<'EOF'
if $programname == 'linux_monitoring' then /var/log/linux_monitoring.log
& stop
EOF

# Перезапуск rsyslog

sudo systemctl restart rsyslog

# Конфиг для logrotate
sudo sh -c 'cat > /etc/logrotate.d/linux_monitoring' <<'EOF'
# sudo sh -с 'cat > /etc/logrotate.d/linux_monitoring' <<'EOF'
/var/log/linux_monitoring.log {
    su root adm
    daily
    rotate 7
    copytruncate
    compress
    missingok
    notifempty
    create 0640 root adm
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF

echo "Установка завершена. Запись логов в /var /log/linux_monitoring.log"


# памятка для использования 
# 4. Создаём тестовый скрипт (если нужен)
# #!/bin/bash
# LOG_TAG="my_script"
# logger -t "$LOG_TAG" "File created: $1"

# chmod +x ~/test_logger.sh