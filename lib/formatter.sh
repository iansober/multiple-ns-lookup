#!/bin/bash

function init_json {
    echo '{"data":[],"errors":[]}'
}

# INPUT:    $@ = array
# OUTPUT:   json formatted array
function array_to_json {
    answer=("$@")
    jq -r -c -n '$ARGS.positional' --args "${answer[@]}"
}

# INPUT:    $1 = nameserver
#           $2 = lookup[].zone (format with parse_lookup_zone preferred)
#           $3 = lookup[].type
#           $4 = lookup[].domain
#           $5 = dns lookup result as json formatted array (array_to_json)
# OUTPUT:   json formatted lookup result
function format_json {
    jq -n -c \
        --arg nameserver "$1" \
        --arg zone "$2" \
        --arg type "$3" \
        --arg domain "$4" \
        --arg fqdn "$4$2" \
        --argjson records "$5" \
        '{nameserver:$nameserver,zone:$zone,type:$type,domain:$domain,fqdn:$fqdn,records:$records}'
}

# INPUT:    $1 = json formatted lookup result (format_json)
#           $2 = json formatted array with data
# OUTPUT:   aggregated lookup results in json format
function append_result {
    jq -c \
        --argjson lookup_json "$1" \
        '.data += [$lookup_json]' <<<"$2"
}

# INPUT:    $1 = json formatted lookup result (format_json)
# OUTPUT:   aggregated lookup results in yaml format
function json_to_yaml {
    yq --yaml-output <<<"$1"
}
