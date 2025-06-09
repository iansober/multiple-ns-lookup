#!/bin/bash

function import_config {
    [[ -a "$1/config.json" ]] && \
        { jq -c -M . "$1/config.json" && return 0 || return 1; }
    [[ -a "$1/config.yaml" ]] && \
        { yq -c -M . "$1/config.yaml" && return 0 || return 1; }
    echo "Configuration file config.json/config.yaml not found." >> /dev/stderr
    return 1
}

function define_output {
    local -a allowed_format=(json pretty_json yaml)
    local output_format
    output_format=$(jq -r -M .output <<<"$1" | sed "s/null/json/")
    if [[ ! "${allowed_format[*]}" =~ $output_format ]]; then 
        echo "Format $output_format is not allowed" >> /dev/stderr
        return 1
    fi
    echo "$output_format"
    return 0
}
