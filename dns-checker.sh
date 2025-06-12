#!/bin/bash

# check required packages
declare -a reqired_packages_try=(
jq
dig
grep
date
sed
)
declare -a optional_packages_try=(
yq
)

for package in "${reqired_packages_try[@]}"; do
    command -v "$package" &>/dev/null || { echo "Error: Required package $package is not installed" >>/dev/stderr; exit 1; }
done

for package in "${optional_packages_try[@]}"; do
    command -v "$package" &>/dev/null || echo "Warning: Optional package $package is not installed" >>/dev/stderr
done

# define script directory
SCRIPT_DIR="${0%/*}"
DOMAIN_VALIDATION_REGEX="^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$"
NAMESERVER_VALIDATION_REGEX="^((25[0-5]|(2[0-4]|1[[:digit:]]|[1-9]|)[[:digit:]])\.?\b){4}$"
NAMESERVER_VALIDATION_REGEX_IPV6="^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$"

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

for nameserver_key in "${!nameservers[@]}"; do
    # validate nameserver ip, delete from array if invalid, lookup if valid
    if [[ -z $(grep -iE "$NAMESERVER_VALIDATION_REGEX" <<<"${nameservers[$nameserver_key]}") ]] \
    && [[ -z $(grep -iE "$NAMESERVER_VALIDATION_REGEX_IPV6" <<<"${nameservers[$nameserver_key]}") ]]; then
        error_description="Invalid nameserver name: ${nameservers[$nameserver_key]}. Exclude ${nameservers[$nameserver_key]} from the nameservers list."
        errors_json=$(json_append_error "$error_description" "" "$errors_json")
    else
        # try to lookup dns server
        nameserver_lookup=$(dns_lookup "${nameservers[$nameserver_key]}")
        # delete from array if nameserver is unreachable or invalid
        if [[  $nameserver_lookup =~ $dns_lookup_failure_pattern ]]; then
            error_description="Error trying nameserver ${nameservers[$nameserver_key]}. Exclude ${nameservers[$nameserver_key]} from the nameservers list."
            errors_json=$(json_append_error "$error_description" "$nameserver_lookup" "$errors_json")
        else
            continue
        fi
    fi
    unset -v "nameservers[$nameserver_key]"
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
        errors_json=$(json_append_error "$error_description" "" "$errors_json")
        continue
        }

    for nameserver in "${nameservers[@]}"; do
        for domain_key in "${!domains[@]}"; do
            # check if item in domains list looks like a domain name
            [[ -z $(grep -iE "$DOMAIN_VALIDATION_REGEX" <<<"${domains[$domain_key]}$zone") ]] && { 
                error_description="Domain name ${domains[$domain_key]} probably is not valid. Exclue ${domains[$domain_key]} from the domains list."
                errors_json=$(json_append_error "$error_description" "" "$errors_json")
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
                    '{datetime:$datetime,
                    nameserver:$nameserver,
                    zone:$zone,
                    domain:$domain,
                    fqdn:$fqdn,
                    type:$type,
                    lookup:$lookup}')
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

if [[ $OUTPUT_FORMAT == "csv" ]]; then
    lookups_to_dict=$(jq '
            [.data[] | {datetime, nameserver, zone, fqdn, type, lookup} 
            | if (.lookup | length) == 0 then
                {datetime, nameserver, zone, fqdn, type, lookup: ""}
            else
                .lookup[] as $ip
                | {datetime, nameserver, zone, fqdn, type, lookup: $ip}
            end]' <<<"$result_json")
    result_csv=$(echo \
            '"Datetime","Nameserver","DNS zone","FQDN","DNS record type","Lookup result"' && \
            jq -r '.[] | [.datetime, .nameserver, .zone, .fqdn, .type, .lookup] | @csv' <<<"$lookups_to_dict")
    echo "$result_csv"
    error_list=$(json_parse ".errors" "$result_json")
    [[ -n $error_list ]] && printf "\nErrors:\n%s\n" "$error_list" >>/dev/stderr
    exit 0
fi

if [[ $OUTPUT_FORMAT == "html" ]]; then
    cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DNS Lookup Report</title>
  <style>
$(cat "$SCRIPT_DIR"/assets/style.css)
</style>
</head>
<body>
  <h1>DNS Lookup Report</h1>
  
  <h2>DNS Query Results</h2>
  <table>
    <thead>
      <tr>
        <th>Timestamp</th>
        <th>Nameserver</th>
        <th>Zone</th>
        <th>Domain</th>
        <th>FQDN</th>
        <th>Record Type</th>
        <th>IP Addresses</th>
      </tr>
    </thead>
    <tbody>
EOF

jq -r '.data[] | 
  "<tr>
    <td class=\"timestamp\">\(.datetime)</td>
    <td>\(.nameserver)</td>
    <td>\(.zone)</td>
    <td>\(.domain)</td>
    <td>\(.fqdn)</td>
    <td>\(.type)</td>
    <td>\(
      if (.lookup | length) == 0 then 
        "<span class=\"no-results\">No results</span>" 
      else 
        "<ul class=\"ip-list\">" + (.lookup[] | "<li>\(.)</li>") + "</ul>" 
      end
    )</td>
  </tr>"' <<<"$result_json"

cat <<EOF
    </tbody>
  </table>

  <h2>Errors</h2>
EOF

jq -r '.errors[] | 
  "<div class=\"error\">
    <strong>Error:</strong> \(.description)
    \(if .message != "" then "<br><span>\(.message)</span>" else "" end)
  </div>"' <<<"$result_json"

cat <<EOF
</body>
</html>
EOF

exit 0
fi
