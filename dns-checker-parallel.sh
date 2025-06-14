#!/bin/bash

SCRIPT_DIR="${0%/*}"

# load libraries
source "$SCRIPT_DIR/lib/core.sh" || { echo "Could not load library core.sh" >>/dev/stderr; exit 1; }
source "$SCRIPT_DIR/lib/configuration.sh" || { echo "Could not load library configuration.sh" >>/dev/stderr; exit 1; }

# load config and validate output format
CONFIG=$(import_config "$SCRIPT_DIR") || exit 1
OUTPUT_FORMAT=$(define_output "$CONFIG") || exit 1

jq . <<<"$CONFIG"

result_json="[]"

while read -r lookup; do
    dig +nosearch +nocomments +nostats +nocmd +noquestion +nomultiline @$lookup | sed -r "s/^(.*)$/$lookup | \1/" &
done < <(jq -r '[.nameservers[] + " " + 
    (.lookup[] |
    ([if (.zone | length) == 0 then 
        .domains[]
    else 
        .domains[] + "." + .zone
    end] | join(" ")) +
    if (.type | length) == 0 then 
        " A"
    else 
        " " + .type
    end)
] | .[]' <<<"$CONFIG")
wait