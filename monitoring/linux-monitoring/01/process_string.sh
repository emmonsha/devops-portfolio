#!/usr/bin/env bash

process_string() {
    local input_strings=$@
    local -a char_array

    # Разбиваем строку на массив символов
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
