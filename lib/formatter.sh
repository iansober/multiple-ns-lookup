#!/bin/bash

# init json formatted array
# OUTPUT as is
function init_json {
    echo '{"data":[]}'
}

# parse bash variable to json formatted list
# INPUT:    $@ = array
# OUTPUT:   json formatted array
# Output example:
#           ["www.example.com-v4.edgesuite.net.","a1422.dscr.akamai.net.","2.16.53.33","2.16.53.27"]
function array_to_json {
    answer=("$@")
    jq -r -c -n '$ARGS.positional' --args "${answer[@]}"
}

# format dns lookup result to json
# INPUT:    $1 = lookup[].zone (format with parse_lookup_zone preferred)
#           $2 = lookup[].type
#           $3 = lookup[].domain
#           $4 = dns lookup result as json formatted array (array_to_json)
# OUTPUT:   json formatted lookup result
# Output example:
#           {"zone":".com","type":"A","domain":"www.example","fqdn":"www.example.com","records":["www.example.com-v4.edgesuite.net.","a1422.dscr.akamai.net.","2.16.53.33","2.16.53.27"]}
function format_json {
    jq -n -c \
        --arg zone "$1" \
        --arg type "$2" \
        --arg domain "$3" \
        --arg fqdn "$3$1" \
        --argjson records "$4" \
        '{zone:$zone,type:$type,domain:$domain,fqdn:$fqdn,records:$records}'
}

# append json formatted lookup result to data
# INPUT:    $1 = json formatted lookup result (format_json)
#           $2 = json formatted array with data
# OUTPUT:   
# Output example:
#           {"data":[{"zone":"","type":"MX","domain":"google.com","fqdn":"google.com","records":["10 smtp.google.com."]},{"zone":"","type":"MX","domain":"google.com","fqdn":"google.com","records":[";; communications error to 127.0.0.1#53: connection refused",";; communications error to 127.0.0.1#53: connection refused",";; communications error to 127.0.0.1#53: connection refused",";; no servers could be reached"]},{"zone":"","type":"MX","domain":"example.com","fqdn":"example.com","records":["0 ."]},{"zone":"","type":"MX","domain":"example.com","fqdn":"example.com","records":[";; communications error to 127.0.0.1#53: connection refused",";; communications error to 127.0.0.1#53: connection refused",";; communications error to 127.0.0.1#53: connection refused",";; no servers could be reached"]},{"zone":".com","type":"A","domain":"google","fqdn":"google.com","records":["142.250.150.100","142.250.150.102","142.250.150.138","142.250.150.113","142.250.150.101","142.250.150.139"]},{"zone":".com","type":"A","domain":"google","fqdn":"google.com","records":[";; communications error to 127.0.0.1#53: connection refused",";; communications error to 127.0.0.1#53: connection refused",";; communications error to 127.0.0.1#53: connection refused",";; no servers could be reached"]},{"zone":".com","type":"A","domain":"www.example","fqdn":"www.example.com","records":["www.example.com-v4.edgesuite.net.","a1422.dscr.akamai.net.","2.16.53.33","2.16.53.27"]},{"zone":".com","type":"A","domain":"www.example","fqdn":"www.example.com","records":[";; communications error to 127.0.0.1#53: connection refused",";; communications error to 127.0.0.1#53: connection refused",";; communications error to 127.0.0.1#53: connection refused",";; no servers could be reached"]}]}
function append_result {
    jq -c \
        --argjson lookup_json "$1" \
        '.data += [$lookup_json]' <<<"$2"
}
