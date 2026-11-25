#!/usr/bin/env bash

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

# Для работы в подпроцессах
export_colors() {
    for key in "${!COLORS[@]}"; do
        export "$key=${COLORS[$key]}"
    done
    export -f color
}