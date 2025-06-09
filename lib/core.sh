#!/bin/bash

function fail_if_empty {
    [[ -z $1 ]] && return 1 || return 0
}

function dns_lookup {
    dig +short @$1 $2$3 $4 &>/dev/stdout
}

function json_parse {
    jq -c -r -M "$1" <<<"$2"
}

function array_to_json {
    array=("$@")
    jq -r -c -n '$ARGS.positional' --args "${array[@]}"
}

function format_error {
    jq -n -c \
        --arg err_descr "$1" \
        --arg err_msg "$2" \
        '{"description":$err_descr,"message":$err_msg}'
}

function json_append_array {
    jq -c \
        --argjson add_item "$1" \
        '. += [$add_item]' <<<"$2"
}
