#!/usr/bin/env bash

generate_combinations() {
    local -n chars=$1
    local max_count=$2
    declare -A unique
    declare -a results
    local count=0
    local max_attempts=$(( max_count * 1000 ))  # Защита от бесконечного цикла
    local attempts=0

    # Вычисляем k только для базовой длины (без увеличения)
    local k=$(calculate_k ${#chars[@]} $max_count)
    # Фиксированная длина массива (без увеличения)
    local -a repeats=()
    for ((i=0; i<${#chars[@]}; i++)); do
        repeats[i]=1
    done

    while (( count < max_count && attempts++ < max_attempts )); do
        # Генерируем текущую комбинацию
        local current=""
        for ((i=0; i<${#chars[@]}; i++)); do
            for ((j=0; j<${repeats[i]}; j++)); do
                current+="${chars[i]}"
            done
        done
        # Проверка уникальности
        if [[ -z "${unique[$current]}" ]]; then
            unique[$current]=1
            results+=("$current")
            ((count++))
            echo "$current"
        fi

        # Увеличиваем счетчики (k-ичная система)
        for ((i=${#repeats[@]}-1; i>=0; i--)); do
            ((repeats[i]++))
            
            if (( repeats[i] > k )); then
                repeats[i]=1
            else
                break
            fi
        done
        # Если перебрали все варианты - увеличиваем k
        if (( i < 0 )); then
            ((k++))
            # echo "Увеличиваем k до $k для поиска большего числа комбинаций" >&2
            repeats[0]=$k  # Начинаем с нового k
        fi
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