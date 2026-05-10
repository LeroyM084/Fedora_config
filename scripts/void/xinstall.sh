#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: xinstall <paquet>"
    exit 1
fi

mapfile -t RESULTS < <(xbps-query -Rs "$1" | awk '{print $2}')

COUNT=${#RESULTS[@]}

if [ "$COUNT" -eq 0 ]; then
    echo "0 package found."
    exit 0
fi

if [ "$COUNT" -eq 1 ]; then
    PACKAGE=${RESULTS[0]}
    echo "One package found: $PACKAGE"
    read -p "Install? [y/N] " confirm
    [[ "$confirm" =~ ^[yY]$ ]] && doas xbps-install -S "$PACKAGE"
    exit 0
fi

PAGE_SIZE=20
TOTAL_PAGES=$(( (COUNT + PAGE_SIZE - 1) / PAGE_SIZE ))
selected=0
MENU_LINES=0

draw_menu() {
    local page=$(( selected / PAGE_SIZE ))
    local start=$(( page * PAGE_SIZE ))
    local end=$(( start + PAGE_SIZE - 1 ))
    [ "$end" -ge "$COUNT" ] && end=$(( COUNT - 1 ))
    local items=$(( end - start + 1 ))

    printf "%d packages found — page %d/%d:\n" "$COUNT" "$(( page + 1 ))" "$TOTAL_PAGES"
    for (( i=start; i<=end; i++ )); do
        if [ "$i" -eq "$selected" ]; then
            printf "\033[1;32m> %s\033[0m\n" "${RESULTS[$i]}"
        else
            printf "  %s\n" "${RESULTS[$i]}"
        fi
    done
    printf "\n\033[2m(↑↓: naviguer, ←→: changer page, Enter: installer, q: quitter)\033[0m\n"
    MENU_LINES=$(( items + 3 ))
}

draw_menu

while true; do
    IFS= read -r -s -n1 key
    if [[ "$key" == $'\x1b' ]]; then
        IFS= read -r -s -n2 -t 0.1 rest
        key="$key$rest"
    fi

    prev_lines=$MENU_LINES
    current_page=$(( selected / PAGE_SIZE ))

    case "$key" in
        $'\x1b[A')
            (( selected-- ))
            [ "$selected" -lt 0 ] && selected=$(( COUNT - 1 ))
            ;;
        $'\x1b[B')
            (( selected++ ))
            [ "$selected" -ge "$COUNT" ] && selected=0
            ;;
        $'\x1b[C')
            if [ "$current_page" -lt $(( TOTAL_PAGES - 1 )) ]; then
                selected=$(( (current_page + 1) * PAGE_SIZE ))
            fi
            ;;
        $'\x1b[D')
            if [ "$current_page" -gt 0 ]; then
                selected=$(( (current_page - 1) * PAGE_SIZE ))
            fi
            ;;
        '')
            printf "\033[%dA\033[J" "$prev_lines"
            PACKAGE="${RESULTS[$selected]}"
            doas xbps-install -S "$PACKAGE"
            exit 0
            ;;
        q|Q)
            printf "\033[%dA\033[J" "$prev_lines"
            echo "Cancelled."
            exit 0
            ;;
    esac

    printf "\033[%dA\033[J" "$prev_lines"
    draw_menu
done
