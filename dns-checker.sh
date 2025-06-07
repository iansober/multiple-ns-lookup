#!/bin/bash

SCRIPT_DIR="${0%/*}"

source "$SCRIPT_DIR/lib/configuration.sh" || { echo "Could not load library configuration.sh" >/dev/stderr; exit 1; }
source "$SCRIPT_DIR/lib/lookup.sh" || { echo "Could not load library lookup.sh" >/dev/stderr; exit 1; }
source "$SCRIPT_DIR/lib/formatter.sh" || { echo "Could not load library formatter.sh" >/dev/stderr; exit 1; }

CONFIG=$(import_config "$SCRIPT_DIR") || exit 1
OUTPUT_FORMAT=$(define_output "$CONFIG") || exit 1

readarray -t nameservers < <(parse_nameservers "$CONFIG")

result_json=$(init_json)
for records in $(jq -r -c -M .lookup[] <<<"$CONFIG"); do
    zone=$(parse_lookup_zone "$records")
    type=$(parse_lookup_record_type "$records")
    for domain in $(parse_lookup_domains "$records"); do
        for nameserver in "${nameservers[@]}"; do
            readarray -t answer < <(lookup_domain "$nameserver" "$domain" "$zone" "$type")
            formatted_answer=$(array_to_json "${answer[@]}")
            lookup_answer=$(format_json "$nameserver" "$zone" "$type" "$domain" "$formatted_answer")
            result_json=$(append_result "$lookup_answer" "$result_json")
        done
    done
done

[[ $OUTPUT_FORMAT == "json" ]] && { echo "$result_json"; exit 0; }
[[ $OUTPUT_FORMAT == "pretty_json" ]] && { echo "$result_json" | jq; exit 0; }
[[ $OUTPUT_FORMAT == "yaml" ]] && { json_to_yaml "$result_json"; exit 0; }
