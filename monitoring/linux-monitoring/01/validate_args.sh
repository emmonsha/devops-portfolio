#!/usr/bin/env bash
print_error() {
	echo "$(color YELLOW "-->> Неправильные параметры:")"
	echo "$(color YELLOW "-->> пример для ввода: ./main.sh /opt/test 4 az 5 az.az 3kb.")"
}

validate_arguments() {
	
	local status=0
	local error=()

		# проверка количества введенных аргументов
	is_args_number_valid $@ || status=1

		# Проверка 1 аргумента
    is_path_valid "$1" || status=1

		# проверка 2 аргумента 
	is_numbers_valid "$2" 2 "количество директорий" || status=1

		# проверка 3 аргумента - латинские буквы для генерации названий папок (до 7 букв)
	is_chars_valid "$3" 3 "список букв для названия папок" || status=1
	
	    # проверка длины 3 аргумента
	is_string_length_valid "$3" 7 3 "список букв для названий папок" || status=1 
	    
		# проверка 4 аргумента - количество файлов в каждой созданной папке.
	is_numbers_valid "$4" 4 "количество файлов" || status=1

		# Проверка 5 агрумента
	is_file_ext_valid "$5" || status=1

		# Проверка 6 аргумента
	check_files_size "$6" || status=1

	echo $status &> /dev/null
	#is_file_size_valid "$6"
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
	[[ $# -eq 6 ]] || { echo "$(color RED "-->> Ошибка, неправильное количество аргументов. Требуется 6 аргументов, введено $# аргументов.")" >&2 ; return 1; };
	return 0
}

is_path_valid() {

	# Проверка на абсолютный путь (начинается с /)
    [[ "$1" =~ ^/ ]] || { echo "$(color RED "-->> Ошибка: путь '$1' не является абсолютным.")" >&2; return 2; }

    [[ -d "$1" ]] || { echo "$(color RED "-->> Ошибка, '$1' такой директории не существует.")" >&2; return 1; }

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

# Проверяет, содержит ли строка ровно одну точку
has_single_dot() { [[ "$(tr -cd '.' <<< "$1" | wc -c)" -eq 1 ]] || { echo "$(color RED "-->> Ошибка: должна быть ровно одна точка. Получено '$1'.")" >&2; return 1; }; }

is_file_ext_valid() {
	local str="$1"
    local status=0
	
	    # Проверка на наличие ровно одной точки
	has_single_dot "$str" || status=1

    # Разделение строки на части по точке
    local file_chars="${str%%.*}"
    local ext_chars="${str##*.}"

	is_chars_valid "$file_chars" 5 "имя файла" || status=1
	is_chars_valid "$ext_chars" 5 "расширение файла" || status=1

	is_string_length_valid "$file_chars" 7 5 "имя файл" || status=1
	is_string_length_valid "$ext_chars" 3 5 "расширение файла" || status=1
	
	#echo $status
	return $status
}

#Поменять

MAX_FILES_SIZE=100
MEASURE="kb"
# Проверяет, что числовая часть корректна (однострочник)
check_numeric_part() { is_numbers_valid "$1" && (( $1 > 0 && $1 <= MAX_FILES_SIZE )); }

# Проверяет, что единица измерения корректна (однострочник)
check_measure_part() { [[ "$1" =~ ^[kK]b$ ]]; }

# Разбивает строку на числовую часть и единицы измерения (однострочник)
split_parts() { [[ "$1" =~ ^([0-9]+)([kK]b)$ ]] && NUMERIC_PART="${BASH_REMATCH[1]}" && MEASURE_PART="${BASH_REMATCH[2]}"; }

# Основная функция проверки размера файла с коротким замыканием
check_files_size() {
    split_parts "$1" || { echo "$(color RED "-->> Ошибка: аргумент № 6 (размер файла). Некорректный формат. Используйте формат типа 12kb или 12Kb.")" >&2; return 1; }
    check_numeric_part "$NUMERIC_PART" || { echo "$(color RED "-->> Ошибка: Размер должен быть числом от 1 до $MAX_FILES_SIZE.")" >&2; return 1; }
    check_measure_part "$MEASURE_PART" || { echo "$(color RED "-->> Ошибка: Единицы измерения должны быть 'kb' или 'Kb'.")" >&2; return 1; }
    
    # echo "$(color YELLOW "Корректный размер файла: $NUMERIC_PART$MEASURE_PART")"
    return 0
}

is_file_size_valid() {
	:
}
