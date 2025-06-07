#!/bin/bash

# parse .nameservers
# INPUT:    $1 = json formatted config
# OUTPUT:   array of nameservers
function parse_nameservers {
    jq -c -r -M .nameservers[] <<<"$1" 2>/dev/stderr
}

# parse .lookup[].zone, add . in front of zone name, delete null
# INPUT:    $1 = json formatted .lookup[] item
# OUTPUT:   zone (string)
function parse_lookup_zone {
    jq -c -r -M .zone <<<"$1" 2>/dev/stderr | \
        sed "s/null//" | \
        sed -r "s/([[:graph:]]+)/\.\1/"
}

# parse .lookup[].type, replace null with A type
# INPUT:    $1 = json formatted .lookup[] item
# OUTPUT:   record type (string)
function parse_lookup_record_type {
    jq -r -c -M .type <<<"$1" 2>/dev/stderr | \
        sed "s/null/A/"
}

# parse .lookup[].domains
# INPUT:    $1 = json formatted .lookup[] item
# OUTPUT:   array of domains
function parse_lookup_domains {
    jq -c -r -M .domains[] <<<"$1" 2>/dev/stderr
}

# lookup DNS record with dig
# INPUT:    $1 = nameserver (string)
#           $2 = domain (string)
#           $3 = zone (string)
#           $4 = record type (string)
# OUTPUT:   answer section in short format (array)
function lookup_domain {
    dig +short @"$1" "$2""$3" "$4"
}
