#!/usr/bin/env bash

source colors.sh
export_colors

LOG_FILE="linux_monitoring.log"
DELETE_LOG="deletion_$(date +'%d%m%Y_%H%M%S').log"
# ERROR_LOG="deletion_errors_$(date +'%d%m%Y_%H%M%S').log"
LOG_TAG="linux_monitoring"

rm -rf delet*

if [[ ! -f "$LOG_FILE" ]]; then 
    echo "$(color RED "-->> Ошибка: файл $LOG_FILE не найден!")" >&2
    exit 1
fi

echo "$(color GREEN "-->> Удаление созданных папок")" | tee -a "$DELETE_LOG"

while IFS= read -r folder || [[ -n "$folder" ]]; do
    folder=$(echo "$folder" | awk -F',' '{print $1}' | xargs)

    if [ -z "$folder" ] || [[ $folder == \#* ]]; then
        continue
    fi

    if [ -d "$folder" ] && [ ! -L "$folder" ]; then
        echo "$(color YELLOW "--> Удаление: $folder")"
        if ! sudo rm -rfv "$folder" >> "$DELETE_LOG" 2>> "$DELETE_LOG"; then
            echo "$(color RED "-->> Ошибка: "$folder"")" >> "$DELETE_LOG"
            logger -t "$LOG_TAG" "DELETE"
        fi
    else 
        [ -d "$folder" ] && [ ! -L "$folder" ] && echo "Папка $folder отсутствует" >> "$DELETE_LOG"
    fi
     
done < "$LOG_FILE"

echo -e "\n"
echo "$(color GREEN "Итоги удаления записаны в: $DELETE_LOG")"
echo "$(color YELLOW "Очистка файла лога linux_monitoring.log")"
>linux_monitoring.log
