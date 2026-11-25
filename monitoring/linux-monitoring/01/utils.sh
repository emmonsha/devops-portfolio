
clear_log_file() {
    local log_file="$1"
    echo "$(color YELLOW "--> Предварительная очистка файла лога.")"
    >"$log_file"
}

clean_system() {
    read -p "Для очистки диска от мусора, созданного этим скриптом нажмите (y Y): " -n 1 -r answer
    echo
    if [[ ! $answer =~ ^[Yy]$ ]]; then
        echo "$(color RED "Не забудьте удалить созданные файлы самостоятельно")"
        exit 0
    fi

    source clean.sh
}

create_files() {
    local current_path="$1"
    local current_file_name="$2"
    local current_ext="$3"
    split_parts "$4"
    local file_size="$NUMERIC_PART" 
    full_name="${current_path}/${current_file_name}_$(date +'%d%m%y').${current_ext}"
    
    if [ ! -f "$full_name" ]; then 
        # sudo fallocate -l "${file_size}K" "${full_name}" # вариант быстрый, но в некоторых случаях может не сработать df -h 
        sudo dd if=/dev/zero of="${full_name}" bs=1 count=0 seek="${file_size}K" 2>/dev/null #вариант с заполнением нулями (будет отражено в dd)
        if [ $? -eq 0 ] ;then 
            echo "$(color GREEN "--> Создан файл ${full_name} размером ${file_size}${MEASURE_PART}")"
            echo "$full_name, $(date +'%d%m%y'), ${file_size}K" >> "$log_file"
        fi
    else 
        echo  "$(color RED "--> Такой файл уже существует $full_name")"
        status=1
    fi
}

check_free_space() {

    local free_space=$(($(df -k --output=avail / | tail -n1) / 1048576))
    if (( free_space < 1 )); then 
        echo "$(color RED "-->> Ошибка: недостаточно свободного места на диске. Завершение работы")" >> "$log_file"
    return 1
    fi
}

create_dir() {
    local current_path="$1"
    local status=0

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

check_strings() {

    local input_string="$@"
    local dir_chars="$1"
    for var in $input_string; do
        if $(is_file_ext_valid "$var" &> /dev/null); then
            # Разделение строки на части по точке
            local file_chars="${var%%.*}"
            local ext_chars="${var##*.}"
            if [[ "${#file_chars}" -lt 4 ]]; then
            file_chars="$(add_chars "$file_chars" 4)"
        fi
        if [[ "${#ext_chars}" -lt 4 ]]; then
            ext_chars="$(add_chars "$ext_chars" 3)"
        fi
    elif [[ "${#var}" -lt 4 ]]; then
        dir_chars="$(add_chars "$var" 4)"
    fi
    done
    echo "$dir_chars $file_chars $ext_chars"
     
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
