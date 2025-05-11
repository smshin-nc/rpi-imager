#!/bin/bash

set -e

declare -A NODE_PATH_MAP
TMP_DTS=$(mktemp)
TMP_NODE_LIST=$(mktemp)

check_tools() {
    for tool in dtc fdtget fdtput whiptail; do
        if ! command -v "$tool" &>/dev/null; then
            echo "ERROR: $tool is not installed."
            exit 1
        fi
    done
}

select_dtb_file() {
    files=$(find ./ -name "*.dtb")
    options=()
    for f in $files; do
        options+=("$f" "")
    done

    whiptail --title "DTB 파일 선택" --menu "수정할 DTB 파일을 선택하세요:" 20 70 10 "${options[@]}" 3>&1 1>&2 2>&3
}

decompile_dtb() {
    dtc -I dtb -O dts -o "$TMP_DTS" "$1"
}

build_node_path_map() {
    local path=""
    while read -r line; do
        if [[ $line =~ ^[[:space:]]*([a-zA-Z0-9,_@.-]+)[[:space:]]*\{$ ]]; then
            local node="${BASH_REMATCH[1]}"
            path="${path}/${node}"
            NODE_PATH_MAP["$node"]="$path"
            echo "$node" >> "$TMP_NODE_LIST"
        elif [[ "$line" =~ ^[[:space:]]*\}[[:space:]]*$ ]]; then
            path="${path%/*}"
        fi
    done < "$TMP_DTS"
}

select_node() {
    options=()
    while read -r line; do
        options+=("$line" "")
    done < "$TMP_NODE_LIST"

    whiptail --title "노드 선택" --menu "수정할 노드를 선택하세요:" 20 70 15 "${options[@]}" 3>&1 1>&2 2>&3
}

select_property_loop() {
    local full_path="${NODE_PATH_MAP[$NODE]}"
    if [ -z "$full_path" ]; then
        whiptail --msgbox "경로를 찾을 수 없습니다: $NODE" 8 40
        return
    fi

    while true; do
        PROPS=$(fdtget -l "$DTB_FILE" "$full_path" 2>/dev/null || echo "")
        options=()
        for prop in $PROPS; do
            options+=("$prop" "")
        done
        options+=("종료" "편집 종료")

        CHOICE=$(whiptail --title "속성 선택" --menu "수정할 속성을 선택하세요:" 20 70 15 "${options[@]}" 3>&1 1>&2 2>&3)

        if [ "$CHOICE" == "종료" ] || [ -z "$CHOICE" ]; then
            break
        fi

        PROP="$CHOICE"
        edit_property "$full_path"
    done
}

edit_property() {
    local full_path="$1"
    OLD_VAL=$(fdtget "$DTB_FILE" "$full_path" "$PROP" 2>/dev/null || echo "(없음)")
    NEW_VAL=$(whiptail --inputbox "현재 값: $OLD_VAL\n새로운 값을 입력하세요 (예: 0x10000000 0x2000 또는 문자열):" 10 70 "" 3>&1 1>&2 2>&3)

    if [ -n "$NEW_VAL" ]; then
        # 값 파싱 및 타입 추론
        ARGS=()
        for val in $NEW_VAL; do
            if [[ "$val" =~ ^0x[0-9a-fA-F]+$ ]]; then
                ARGS+=("$val")
            elif [[ "$val" =~ ^[0-9]+$ ]]; then
                ARGS+=("$val")
            else
                ARGS+=("--type=s" "$val")
            fi
        done

        fdtput "$DTB_FILE" "$full_path" "$PROP" "${ARGS[@]}" && \
        whiptail --msgbox "$full_path:$PROP 속성이 성공적으로 수정되었습니다." 8 60
    fi
}

# ========= Main =========
check_tools

DTB_FILE=$(select_dtb_file)
decompile_dtb "$DTB_FILE"
build_node_path_map

NODE=$(select_node)
select_property_loop

rm -f "$TMP_DTS" "$TMP_NODE_LIST"
