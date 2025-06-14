#!/bin/bash

set -x

SCRIPT_DIR="${0%/*}"

# load libraries
source "$SCRIPT_DIR/lib/core.sh" || { echo "Could not load library core.sh" >>/dev/stderr; exit 1; }
source "$SCRIPT_DIR/lib/configuration.sh" || { echo "Could not load library configuration.sh" >>/dev/stderr; exit 1; }

# load config and validate output format
CONFIG=$(import_config "$SCRIPT_DIR") || exit 1
OUTPUT_FORMAT=$(define_output "$CONFIG") || exit 1

jq . <<<"$CONFIG"

result_json="[]"

echo -n >./tmp/lookup_results 


while read -r lookup; do
    {
        nameserver=$(sed -r "s/^([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+).*/\1/" <<<"$lookup")
        dig +nosearch +nocomments +nostats +nocmd +noquestion +nomultiline @$lookup | sed -r "s/^(.*)$/$nameserver \1/" >>./tmp/lookup_results 
    } &
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

while read -r query_result; do
        nameserver=$(cut -f 1 <<<"$query_result") 
        fqdn=$(cut -f 2 <<<"$query_result") 
        type=$(cut -f 5 <<<"$query_result") 
        result=$(cut -f 6- <<<"$query_result") 
        result_json=$(jq -c \
                --arg nameserver "$nameserver" \
                --arg fqdn "$fqdn" \
                --arg type "$type" \
                --arg result "$result" \
                    '. += [{nameserver:$nameserver,
                    fqdn:$fqdn,
                    type:$type,
                    result:$result}]' <<<"$result_json")
done < <(cat ./tmp/lookup_results | sed -r "s/[[:blank:]]+/\t/g")

jq -r . <<<$result_json