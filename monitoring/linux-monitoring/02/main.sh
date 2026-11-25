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


#********
# ПРОВЕРКА АРГУМЕНТОВ 
#********

print_error() {
	echo "$(color YELLOW "-->> Неправильные параметры:")"
	echo "$(color YELLOW "-->> пример для ввода: ./main.sh az az.az 1Mb.")"
}

validate_arguments() {
	
	local status=0
	local error=()

		# проверка количества введенных аргументов
	is_args_number_valid $@ || status=1

		# Проверка 1 аргумента - латинские буквы для генерации названий папок (до 7 букв)
	is_chars_valid "$1" 2 "список букв для названия папок" || status=1
	
	    # проверка длины 1 аргумента
	is_string_length_valid "$1" 7 2 "список букв для названий папок" || status=1 

		# Проверка 2 агрумента 
	is_file_ext_valid "$2" || status=1

		# Проверка 3 аргумента
	check_files_size "$3" || status=1

	echo $status &> /dev/null

	echo $status &> /dev/null

	if [[ "$status" -ne 0 ]]; then 
	print_error "$status"
	return 1
	else 
	echo "$(color GREEN "-->> Параметры введены правильно, приступаем к обработке полученных данных")"
	return 0
	fi
}

is_args_number_valid() {
	[[ $# -eq 3 ]] || { echo "$(color RED "-->> Ошибка, неправильное количество аргументов. Требуется 3 аргумента, введено $# аргументов.")" >&2 ; return 1; };
	return 0
}

is_numbers_valid() {
	
	[[ "$1" =~ ^[0-9]+$ ]] || { echo "$(color RED "-->> Ошибка: аргумент № $2 ($3) должен быть положительным числом, получено '$1'.")" >&2; return 1; };
	
	[[ ! "$1" -eq 0 ]] || { echo "$(color RED "-->> Ошибка: аргумента $2 ($3) не должен быть равен нулю. Получено '$1'.")" >&2; return 2; };

	return 0;
}

is_string_length_valid() {
	[[ "${#1}" -le "$2" ]] || {  echo "$(color RED "-->> Ошибка: аргумент № $3 ($4) должен состоять не более чем из $2 букв, получено '$1' (длина: ${#1})")" >&2; return 1; };
	return 0
}

is_chars_valid() {
	[[ "$1" =~ ^[a-zA-Z]+$ ]] || { echo "$(color RED "-->> Ошибка: агрумент № $2 ($3) должен содержать только буквы английского алфавита. Получено '$1'.")" >&2; return 1; };
}

has_single_dot() { [[ "$(tr -cd '.' <<< "$1" | wc -c)" -eq 1 ]] || { echo "$(color RED "-->> Ошибка: должна быть ровно одна точка. Получено '$1'.")" >&2; return 1; }; }

is_file_ext_valid() {
	local str="$1"
    local status=0
	
	has_single_dot "$str" || status=1

    local file_chars="${str%%.*}"
    local ext_chars="${str##*.}"

	is_chars_valid "$file_chars" 2 "имя файла" || status=1
	is_chars_valid "$ext_chars" 2 "расширение файла" || status=1

	is_string_length_valid "$file_chars" 7 2 "имя файл" || status=1
	is_string_length_valid "$ext_chars" 3 2 "расширение файла" || status=1
	
	return $status
}

MAX_FILES_SIZE=100
MEASURE="Mb"

check_numeric_part() { is_numbers_valid "$1" && (( $1 > 0 && $1 <= MAX_FILES_SIZE )); }

check_measure_part() { [[ "$1" =~ ^[mM]b$ ]]; }

split_parts() { [[ "$1" =~ ^([0-9]+)([mM]b)$ ]] && NUMERIC_PART="${BASH_REMATCH[1]}" && MEASURE_PART="${BASH_REMATCH[2]}"; }

check_files_size() {
    split_parts "$1" || { echo "$(color RED "-->> Ошибка: аргумент № 3 (размер файла). Некорректный формат. Используйте формат типа 12mb или 12Mb.")" >&2; return 1; }
    check_numeric_part "$NUMERIC_PART" || { echo "$(color RED "-->> Ошибка: Размер должен быть числом от 1 до $MAX_FILES_SIZE.")" >&2; return 1; }
    check_measure_part "$MEASURE_PART" || { echo "$(color RED "-->> Ошибка: Единицы измерения должны быть 'mb' или 'Mb'.")" >&2; return 1; }
    
    return 0
}

is_file_size_valid() {
	:
}

#********
# УТИЛИТЫ
#********


clear_log_file() {
    local log_file="$1"
    echo "$(color YELLOW "--> Предварительная очистка файла лога.")"
    >"$log_file"
}

clean_system() {
    read -p "Для очистки диска от мусора, созданного этим скриптом, нажмите (y Y): " -n 1 -r answer
    echo
    if [[ ! $answer =~ ^[Yy]$ ]]; then
        echo "$(color RED "Не забудьте удалить созданные файлы самостоятельно")"
        echo "$(color RED "Для автоматического удаления запустите скрипт ./clean.sh")"
        exit 0
    fi

    source clean.sh
}

create_files() {
    local full_name="$1"
    split_parts "$2"
    local file_size="$NUMERIC_PART"

    
    if [ ! -f "$full_name" ]; then 
        sudo fallocate -l "${file_size}M" "${full_name}" # вариант быстрый, но в некоторых случаях может не сработать df -h 
        # sudo dd if=/dev/zero of="${full_name}" bs=1 count=0 seek="${file_size}" 2>/dev/null #вариант с заполнением нулями (будет отражено в dd)
        if [ $? -eq 0 ] ;then 
            echo "$(color GREEN "--> Создан файл ${full_name} размером ${file_size}${MEASURE_PART}")"
        fi
    else 
        echo  "$(color RED "--> Такой файл уже существует $full_name")"
        status=1
    fi
}

check_free_space() {

    free_space=$(df -h / | awk 'NR==2 {print $4}')
    if [[ "$free_space" == *M ]]; then 
        logger -t "${params_ref[LOG_TAG]}" "SYSTEM | ERROR |недостаточно свободного места на диске. Завершение работы | $(date +'%d%m%y')" 
    return 1
    fi
    return 0
}

create_folder() {
    local current_path="$1"
    local status=0
    local log_file="linux_monitoring.log"

    if [ ! -d "$current_path" ]; then 
        sudo mkdir -p "$current_path"
        if [ $? -eq 0 ]; then
            echo "$(color GREEN "--> Создана папка $current_path")"
            echo "$current_path, $(date +'%d%m%y')" >> "$log_file"
            sudo chmod 755 "$current_path" >> /dev/null
            status=0
        else 
            echo "$(color RED "-->> Ошибка создания папки $current_path")" >> "$log_file"
        fi
    else 
        echo  "$(color RED "--> Такая папка уже существует $current_path")"
        status=1
    fi
    
    return "$status"
}

split_string() {
    local input_string="$@"

    for var in $input_string; do
        local file_chars="${var%%.*}"
        local ext_chars="${var##*.}"
        if [[ "${#ext_chars}" -lt 3 ]]; then
        ext_chars="$(add_chars "$ext_chars" 3)"
        fi
    done
    echo "$file_chars $ext_chars"
}

add_chars() {
    
    local input_string="$1"
    local actual_size="$2"
    local last_char="${input_string: -1}"

    while [[ ${#input_string} -lt "$2" ]]; do
        input_string="${input_string}${last_char}"
    done
    echo "$input_string"
}


get_path() {
    local current_path=$(pwd)
    # current_path="/bin"
    if [[ "$current_path" == */bin* ]] || [[ "$current_path" == */sbin* ]]; then
        echo "$(color RED "-->> Ошибка: недопустимый путь. Путь ${current_path} содержит /bin или /sbin.")" >&2
        echo "$(color MAGENTA "-->> Для дальнейшей проверки скрипта смените текущую папку \n**** Завершение работы ****")" >&2
        exit 1
    fi

    echo $current_path
}

process_string() {
    local input_strings=$@
    local -a char_array

    for str_var in "$@"; do
        local str_len=()
        str_len=${#str_var}
        char_array=()
        for ((i=0; i<str_len; i++)); do
            char_array[i]="${str_var:i:1}"
        done
        printf "${char_array[*]}"
    done
}

#********
# ГЕНЕРАТОР МУСОРА
#********


generate_() {
    local -n params_ref="$1"
    local folder_chars="${params_ref[input_folder_chars]}"
    local max_count="${params_ref[total_count]}"
    local file_ext="${params_ref[input_file_ext]}"
    local f_size="${params_ref[file_size]}"
    local LOG_FILE_TAG="${params_ref[LOG_TAG]}"
    local path_="${params_ref[folder_path]}"
    local MODE="$2"

    declare -A unique
    local count=0
    read file_chars ext_chars <<< "$(split_string $file_ext)"
    read -ra _chars <<< "$(check_mode $MODE $folder_chars $file_chars)"
    local min_length=$(( ${#_chars[@]} > 5 ? ${#_chars[@]} : 5 ))
    # echo "${_chars[@]}"

    local N=${#_chars[@]}
    local k=$(calculate_k $N $max_count)
    local -a repeats=($(for ((i=0; i<N; i++)); do echo 1; done))
    
    local -a increment_indices=()
    local prev_char=""
    for ((i=0; i<N; i++)); do
        if [[ "${_chars[i]}" != "$prev_char" ]]; then
            increment_indices+=($i)
            prev_char="${_chars[i]}"
        fi
    done

    while (( count < max_count )); do
        local current=""
        for ((i=0; i<N; i++)); do
            current+=$(printf "%.0s${_chars[i]}" $(seq 1 ${repeats[i]}))
        done

        if [[ -z "${unique[$current]}" ]]; then
            unique[$current]=1
            if [[ ${#current} -lt "$min_length" ]]; then
                continue
            fi
            process_gen "$MODE" "$path_" "$current" "$ext_chars" "$f_size" "$LOG_FILE_TAG" || break
            ((count++))
        fi

        for ((i=${#increment_indices[@]}-1; i>=0; i--)); do
            local idx=${increment_indices[i]}
            ((repeats[idx]++))
            
            if (( repeats[idx] > k )); then
                repeats[idx]=1

                if (( i == 0 )); then
                    ((k++))
                    repeats[${increment_indices[0]}]=$k
                fi
            else
                break
            fi
        done
    done
}

calculate_k() {
    local N=$1
    local max=$2
    local k=1
    while (( k ** N < max )); do
        ((k++))
    done
    echo $k
}

check_mode() {
    local MODE="$1"
    local folder_chars=$2
    local file_chars=$3
    local _chars=""

    case "$MODE" in 
        "FOLDER")
        read _chars <<< "$(process_string $folder_chars)"
        ;;
        "FILE")
        read _chars <<< "$(process_string $file_chars)"
        ;;
    esac
    echo "$_chars"
}

process_gen() {
    local MODE="$1"
    local path_="$2"
    local current=$3
    local ext_chars="$4"
    local f_size="$5"
    local LOG_FILE_TAG="$6"

    if [[ "$MODE" == FOLDER ]]; then
        full_path="${path_}/${current}_$(date +'%d%m%y')"
        echo "$full_path"
    elif [[ "$MODE" == FILE ]]; then
        full_name="${path_}/${current}_$(date +'%d%m%y').${ext_chars}"
        name_size=$(echo - n "${current}_$(date +'%d%m%y').${ext_chars}" | wc -c)
        if [[ "$name_size" -lt 255 ]]; then
            create_files "$full_name" "$f_size"
        if [ -f "$full_name" ]; then
            echo "$full_name $LOG_FILE_TAG" >> linux_monitoring.log
            logger -t $LOG_FILE_TAG "CREATE | file | $full_name | $(date +'%d%m%y')"
        else  
            echo "Ошибка, файл $full_name не создан" > linux_monitoring.log
            logger -t $LOG_FILE_TAG "ERROR | create | $full_name | $(date +'%d%m%y')"
        fi

        if ! check_free_space; then 
            free_space="$(df -h / | awk 'NR==2 {print $4}')"
            echo "$(color MAGENTA "-->> Внимание достигнут предел свободного места $free_space < 1 Гб")"
            clean_system
            exit 1
        fi
        else 
            echo "$(color RED "Ошибка: слишком длинное имя файла. Переходим в другую папку")"
            logger -t $LOG_FILE_TAG "ERROR | file name too long | $full_name | $(date +'%d%m%y')"
            return 1
        fi
    fi
}

main() { 
    echo "$(color YELLOW "-->> Проверка введенных аргументов.")"
    validate_arguments "$@" || return 1  
    declare -A params=(
        [input_folder_chars]="$1"
        [input_file_ext]="$2"
        [file_size]="$3"
        [total_count]=0
        [folder_path]=""
        [LOG_TAG]="linux_monitoring"
    )

    echo "$(color YELLOW "-->> Проверка текущего пути")"
    params[folder_path]=$(get_path) || exit 1 # получаем путь с проверкой на /bin /sbin
    params[total_count]=$((RANDOM % 100 + 1 ))
    echo "$(color YELLOW "--> Количество создаваемых папок: ${params[total_count]}")"
    echo "$(color YELLOW "-->> Генерация вариантов наименований папок.")"  
    mapfile -t folder_names_array < <(generate_ params FOLDER)
    echo "$(color YELLOW "--> Начинаю создание папок и файлов.")"

    for folder_name in "${folder_names_array[@]}"; do
        file_number="$RANDOM"
        echo "$(color YELLOW "--> Количество создаваемых файлов $file_number")"
        echo "$(color YELLOW "-->> Генерация файлов.")"
        create_folder "$folder_name"
        if [ -d "$folder_name" ]; then
            logger -t "${params[LOG_TAG]}" "CREATE | folder | $folder_name | $(date +'%d%m%y')"
        fi
        params[folder_path]="$folder_name"
        params[total_count]="$file_number"
        generate_ params FILE
    done

    echo "$(color MAGENTA "Скрипт завершен.")"

    clean_system
}

main $@