#!/usr/bin/env bash

#******
# ЦВЕТОВОЕ ОФОРМЛЕНИЕ
#******

declare -gA COLORS=(
    [RED]='\033[0;31m'
    [GREEN]='\033[0;32m'
    [YELLOW]='\033[0;33m'
    [MAGENTA]='\033[0;35m'
    [NC]='\033[0m'
)

color() {
    local color_name="$1"
    local message="$2"
    echo -e "${COLORS[$color_name]}${message}${COLORS[NC]}"
}

export_colors() {
    for key in "${!COLORS[@]}"; do
        export "$key=${COLORS[$key]}"
    done
    export -f color
}

export_colors

# ********
# Удаление по лог файлу 
# ********


del_by_log() {
    
    local log_file=$(sudo find /var -type f -name "linux_monitoring.log")
    process_del "$log_file"
}

process_del() {
    local log_file="$1"
    local SYSLOG_TAG="linux_monitoring"
    local count=0
    while IFS= read -r line; do
        if [[ "$line" == *"CREATE"*"folder"* ]]; then
            folder=$(echo "$line" | awk -F'|' '{print $3}' | xargs)
            if [[ -d "$folder" ]]; then
                
                sudo rm -rvf "$folder" >> /dev/null
                if [ "$?" -eq 0 ]; then 
                    echo "$(color YELLOW "Удаляем папку и все содержимое: $folder")"
                    logger -t "$SYSLOG_TAG" "DELETE | folder | "$folder" | $(date +'%d%m%y')"
                    ((count++))
                fi
            fi
        fi
    done < "$log_file"

    [[ $count -ne 0 ]] && echo "$(color GREEN "Удаление завершено. всего удаленных папок: $count")"
}

# ********
# Удаление по дате 
# ********


del_by_date() {
    local time_range="$1"
    start_time=${time_range%-*}
    end_time=${time_range#*-}
    
    
    start_time=$(echo "$start_time" | sed -E 's/(..)(..)(..)(..)(..)/20\3-\2-\1 \4:\5:00/')
    end_time=$(echo "$end_time" | sed -E 's/(..)(..)(..)(..)(..)/20\3-\2-\1 \4:\5:00/')
    echo "$start_time $end_time"
    parse_by_time 
}

parse_by_time() {
    while IFS= read -r -d $'\0' folder; do
        if  [[ ! "$(pwd)" == "$folder"  ]]; then
            echo "$(color YELLOW "Удаление папки $folder")"
            sudo rm -rvf "$folder"
            if [ "$?" -eq 0 ]; then 
                logger -t linux_monitoring "DELETE | folder | "$folder" | $(date +'%d%m%y')"
            fi
        fi
    done < <(find "$(pwd)" -newermt "$start_time" ! -newermt "$end_time" -type d -print0)
}


# ********
# Удаление по маске
# ********

del_by_mask() {
    local input_mask="$1"
    local mask="*${input_mask}*"
    SYSLOG_TAG="linux_monitoring"

    echo "$(color YELLOW "Поиск и удаление файлов по маске ${input_mask}")"


    find "$(pwd)" \( -type f -o -type d \) -name "${mask}" -print0 | while IFS= read -r -d '' target; do
            if [[ -d "$target" ]]; then
                TYPE="folder"
            elif [[ -f "$target" ]]; then 
                TYPE="file"
            fi   
            if sudo rm -rvf "$target" >> /dev/null ; then
                logger -t "$SYSLOG_TAG" "DELETE | "$TYPE" | "$target" | $(date +'%d%m%y')"
                echo "DELETE | "$TYPE" | "$target" | $(date +'%d%m%y')">${SYSLOG_TAG}.log
            else 
                logger -t "$SYSLOG_TAG" "DELETE FAILED | "$TYPE" | "$target" | $(date +'%d%m%y')" &>2
            fi
        done

}

# ********
# основной скрипт
# ********

print_error() {
    echo "$(color RED "Ошибка:")"
    echo "$(color YELLOW "Использование: $0 <параметр>")"
    echo "$(color YELLOW "Параметры:")"
    echo "$(color YELLOW "  log                     - удаление по лог-файлу")"
    echo "$(color YELLOW "  ДДММГГЧЧММ-ДДММГГЧЧММ   - удаление по дате и времени создания")"
    echo "$(color YELLOW "  маска                   - удаление по маске имени и даты (abc_220725)")"
    exit 1
}

parser() {
    if [[ $# -ne 1 ]]; then
        print_error
        exit 1
    fi

    local input_arg="$1" 
    case "$input_arg" in
    log)
        del_by_log
        ;;
    *-*)
        if [[ "$input_arg" =~ ^[0-9]{10}-[0-9]{10}$ ]]; then
            del_by_date "$input_arg"
        else
            echo "$(color YELLOW "Неверный формат. Используйте ДДММГГЧЧММ-ДДММГГЧЧММ (например, 0101241200-0101241500)")"
            exit 1
        fi
        ;;
    *)
        if [[ "$input_arg" =~ ^[[:alpha:]]+_[0-9]{6}$ ]]; then
            del_by_mask "$input_arg"
        else
            echo "$(color YELLOW "Неверная маска. Используйте только буквы и подчеркивания и дату в требуемом формате (например, abc_DDMMYY)")"
            exit 1
        fi
        ;;
    esac

    echo "$(color GREEN "Скрипт завершен")"
    echo "$(color GREEN "Итоги удаления записаны в: /$DELETE_LOG")"
    echo "$(color YELLOW "Очистка файла лога linux_monitoring.log")"

}

parser $@