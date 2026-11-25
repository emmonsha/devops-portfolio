#!/usr/bin/env bash

source ./colors.sh
source validate_args.sh
source process_arrays.sh
source utils.sh
export_colors

main() { 
    echo "$(color YELLOW "-->> Проверка введенных аргументов.")"
    validate_arguments "$@" || return 1
    local path_dir=$1
    local dir_number=$2
    local input_dir_chars=$3
    local file_number=$4
    local input_file_ext=$5
    local file_size=$6
    local file_chars
    local ext_chars
    local dir_chars
    log_file="linux_monitoring.log"

    read dir_chars file_chars ext_chars <<< "$(check_strings $input_dir_chars $input_file_ext)"

    echo "$(color YELLOW "-->> Генерация вариантов наименований директорий.")"
    mapfile -t dir_names_array < <(test "$dir_chars" "$dir_number")
    
    echo "$(color YELLOW "-->> Генерация вариантов наименований файлов.")"
    mapfile -t file_names_array < <(test "$file_chars" "$file_number")

    clear_log_file "$log_file"

    echo "$(color YELLOW "--> Начинаю создание папок и файлов.")"

    for dir_name in "${dir_names_array[@]}"; do
        full_path="${path_dir}/${dir_name}_$(date +'%d%m%y')"
        [ -d "$full_path" ] || >> "$log_file" 
        create_dir "$full_path"
        if [ -d "$full_path" ]; then 
            for file_name in "${file_names_array[@]}"; do
                create_files "$full_path" "$file_name" "$ext_chars"
                check_free_space || return 1
            done
        fi
    done

    echo "$(color MAGENTA "Скрипт завершен.")"

    clean_system
}

main $@
