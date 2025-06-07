# import json or yaml formatted configuration file
# fail if config does not exist or invalid
function import_config {
    [[ -a config.json ]] && { jq -c -M . config.json && return 0 || exit 1; }
    [[ -a config.yaml ]] && { yq -c -M . config.yaml && return 0 || exit 1; }
    echo "Configuration file config.json/config.yaml not found." >> /dev/stderr
    exit 1
}

# check if output format is defined and allowed
# set json if not defined
# exit if not allowed
function define_output {
    local -a allowed_format=(json)
    local output_format
    output_format=$(jq -M .output <<<"$1" | sed "s/null/json/")
    if [[ ! "${allowed_format[*]}" =~ $output_format ]]; then 
        echo "Format $output_format is not allowed" >> /dev/stderr
        exit 1
    fi
    echo "$output_format"
    return 0
}
