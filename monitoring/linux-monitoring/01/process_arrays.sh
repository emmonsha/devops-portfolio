#!/usr/bin/env bash

# Подключаем функции
source process_string.sh
source generate_names.sh

test () {
    local tmp_string="$1"
    local tmp_number="$2"

    read -ra char_array <<< "$(process_string $tmp_string)"

    generate_combinations char_array $tmp_number
}
