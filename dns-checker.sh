#!/bin/bash

# define script directory
SCRIPT_DIR="${0%/*}"
DOMAIN_VALIDATION_REGEX="^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$"

# load libraries
source "$SCRIPT_DIR/lib/core.sh" || { echo "Could not load library core.sh" >>/dev/stderr; exit 1; }
source "$SCRIPT_DIR/lib/configuration.sh" || { echo "Could not load library configuration.sh" >>/dev/stderr; exit 1; }

# load config and validate output format
CONFIG=$(import_config "$SCRIPT_DIR") || exit 1
OUTPUT_FORMAT=$(define_output "$CONFIG") || exit 1

# verify required lists existion
json_parse ".nameservers[]" "$CONFIG" 1>/dev/null || { echo "Error: No nameservers list in config" >>/dev/stderr; exit 1; }
json_parse ".lookup[]" "$CONFIG" 1>/dev/null || { echo "Error: No lookup list in config" >>/dev/stderr; exit 1; }

# set datetime format
DATETIME_FORMAT=$(json_parse ".datetime_format" "$CONFIG" 2>/dev/null | sed "s/null//") || DATETIME_FORMAT='--iso-8601=seconds'
fail_if_empty "$DATETIME_FORMAT" || DATETIME_FORMAT='--iso-8601=seconds'

# init json arrays
lookup_json="[]"
errors_json="[]"

# try nameservers
dns_lookup_failure_pattern=".*failure.*|.*no servers could be reached.*"

readarray -t nameservers < <(json_parse ".nameservers[]" "$CONFIG")
fail_if_empty "${nameservers[*]}" || { echo "Error: Empty nameservers list" >>/dev/stderr; exit 1; }

for key in "${!nameservers[@]}"; do
    nameserver_lookup=$(dns_lookup "${nameservers[$key]}")
    # delete from array if nameserver is unreachable or invalid
    if [[  $nameserver_lookup =~ $dns_lookup_failure_pattern ]]; then
        error_description="Error trying nameserver ${nameservers[$key]}. Exclude ${nameservers[$key]} from the nameservers list."
        formatted_error=$(format_error "$error_description" "$nameserver_lookup")
        errors_json=$(json_append_array "$formatted_error" "$errors_json")
    else
        continue
    fi
    unset -v "nameservers[$key]"
    declare -p nameservers &>/dev/null
done

# lookup dns records
while read -r lookup_item; do
    type=$(json_parse ".type" "$lookup_item" | sed "s/null/A/")
    zone=$(json_parse ".zone" "$lookup_item" | sed "s/null//" | sed -r "s/([[:graph:]]+)/\.\1/")
    readarray -t domains < <(json_parse ".domains[]" "$lookup_item" 2>/dev/null)

    # skip if empty domains list, log error
    fail_if_empty "${domains[*]}" || { 
        error_description="Error parsing domains list in item $lookup_item"
        formatted_error=$(format_error "$error_description" "$(json_parse ".domains[]" "$lookup_item" &>/dev/stdout)")
        errors_json=$(json_append_array "$formatted_error" "$errors_json")
        continue
        }

    for nameserver in "${nameservers[@]}"; do
        for domain_key in "${!domains[@]}"; do
            # check if item in domains list looks like a domain name
            [[ -z $(grep -iE "$DOMAIN_VALIDATION_REGEX" <<<"${domains[$domain_key]}$zone") ]] && { 
                error_description="Domain name ${domains[$domain_key]} probably is not valid. Exclue ${domains[$domain_key]} from the domains list."
                formatted_error=$(format_error "$error_description" "")
                errors_json=$(json_append_array "$formatted_error" "$errors_json")
                unset -v "domains[$domain_key]"
                declare -p domains &>/dev/null
                continue
            }
            # lookup domains
            datetime=$(date $DATETIME_FORMAT)
            readarray -t domain_lookup < <(dns_lookup "$nameserver" "${domains[$domain_key]}" "$zone" "$type")
            formatted_lookup=$(array_to_json "${domain_lookup[@]}")
            formatted_result=$(jq -n -c \
                --arg datetime "$datetime" \
                --arg nameserver "$nameserver" \
                --arg zone "$zone" \
                --arg domain "${domains[$domain_key]}" \
                --arg fqdn "${domains[$domain_key]}$zone" \
                --arg type "$type" \
                --argjson lookup "$formatted_lookup" \
                '{datetime:$datetime,nameserver:$nameserver,zone:$zone,domain:$domain,fqdn:$fqdn,type:$type,lookup:$lookup}')
            lookup_json=$(json_append_array "$formatted_result" "$lookup_json")
        done
    done
done <<<"$(json_parse ".lookup[]" "$CONFIG")"

# merge lookup result list and errors list 
result_json=$(jq -n -c \
                --argjson lookups "$lookup_json" \
                --argjson errors "$errors_json" \
                '{data:$lookups,errors:$errors}')

# output formatter
[[ $OUTPUT_FORMAT == "json" ]] && { echo "$result_json"; exit 0; }
[[ $OUTPUT_FORMAT == "pretty_json" ]] && { echo "$result_json" | jq; exit 0; }
[[ $OUTPUT_FORMAT == "yaml" ]] && { yq --yaml-output <<<"$result_json"; exit 0; }
