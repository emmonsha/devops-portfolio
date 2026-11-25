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

main () {
    local arg="$1"
    if [[ $# -ne 1 ]] || [[ ! "$arg" =~ ^[0-9]$ ]] || [[ "$arg" -gt 4 ]] || [[ "$arg" -lt 1 ]]; then
        echo  -n "$(color RED "Ошибка:")"
        echo "$(color YELLOW " неправильные аргументы. В качестве аргумента введите число от 1 до 4
        использование: ./main.sh 1")"
        return 1
    fi

    case "$arg" in
        1)
        sort_by_status_code $@
        ;;
        2)
        sort_by_unique_ip $@
        ;;
        3)
        parse_by_error_code $@
        ;;
        4)
        parse_by_error_code_uniq_ip $@
        ;;

    esac

    echo "$(color GREEN "Скрипт завершен")"
    
}

sort_by_status_code() {
    
    for ((i=0; i < 5; i++)); do
        awk '{print$0}' ../04/access${i}.log | sort -k9 >sorted_by_status_code${i}.log
    done
}

sort_by_unique_ip() {

    declare -A seen
    for ((i=0; i < 5; i++)); do
        awk '!seen[$1]++ {print$1}' ../04/access${i}.log > list_of_unique_ip${i}.log
    done
}

parse_by_error_code() {

    for (( i=0; i<5; i++ )); do
    awk '$9 ~ /^[45]/ {print}' ../04/access${i}.log > list_of_error${i}.log
    done
}

parse_by_error_code_uniq_ip() {

    for (( i=0; i<5; i++ )); do
    awk '$9 ~ /^[45]/ {print$1}' ../04/access${i}.log > list_of_error_uniq${i}.log
    done
}

main $@