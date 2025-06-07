# lib/formatter.sh

## function init_json

Inits json formatted array.

**Output**:
```
{"data":[],"errors":[]}
```

## function array_to_json

Transform bash variable to json formatted list.

**Input**:
1. Array

**Output**: json formatted array

### Examples:

#### 1. *Input*:
```
www.example.com-v4.edgesuite.net. a1422.dscr.akamai.net. 2.16.53.33 2.16.53.27
```

*Output*:
```
["www.example.com-v4.edgesuite.net.","a1422.dscr.akamai.net.","2.16.53.33","2.16.53.27"]
```

#### 2. *Input*:
```
140.82.121.3
```

*Output*:
```
["140.82.121.3"]
```

## function format_json

Transforms DNS lookup result to json.

**Input**:
1. nameserver
2. lookup[].zone (format with parse_lookup_zone preferred)
3. lookup[].type
4. lookup[].domain
5. DNS lookup result as json formatted array (transformed with array_to_json)

**Output**: json formatted lookup result

### Examples:

#### 1. *Input*:
```
8.8.8.8 '' MX google.com '["10 smtp.google.com."]'
```

*Output*:
```
{"nameserver":"8.8.8.8","zone":"","type":"MX","domain":"google.com","fqdn":"google.com","records":["10 smtp.google.com."]}
```

#### 2. *Input*:
```
8.8.8.8 .com A google '["142.250.150.138","142.250.150.113","142.250.150.102","142.250.150.139","142.250.150.100","142.250.150.101"]'
```

*Output*:
```
{"nameserver":"8.8.8.8","zone":".com","type":"A","domain":"google","fqdn":"google.com","records":["142.250.150.138","142.250.150.113","142.250.150.102","142.250.150.139","142.250.150.100","142.250.150.101"]}
```

## function append_result

Appends json formatted lookup result to .data[].

**Input**:
1. Json formatted lookup result (format_json)
2. Json formatted array with data

**Output**: aggregated lookup results in json format

### Examples:

#### 1. *Input*:
```
'{"nameserver":"8.8.8.8","zone":"","type":"MX","domain":"google.com","fqdn":"google.com","records":["10 smtp.google.com."]}' '{"data":[],"errors":[]}'
```

*Output*:
```
{"data":[{"nameserver":"8.8.8.8","zone":"","type":"MX","domain":"google.com","fqdn":"google.com","records":["10 smtp.google.com."]}],"errors":[]}
```

#### 2. *Input*:
```
'{"nameserver":"8.8.8.8","zone":".com","type":"A","domain":"google","fqdn":"google.com","records":["142.250.150.138","142.250.150.113","142.250.150.102","142.250.150.139","142.250.150.100","142.250.150.101"]}' '{"data":[{"nameserver":"8.8.8.8","zone":"","type":"MX","domain":"google.com","fqdn":"google.com","records":["10 smtp.google.com."]}],"errors":[]}'
```

*Output*:
```
{"data":[{"nameserver":"8.8.8.8","zone":"","type":"MX","domain":"google.com","fqdn":"google.com","records":["10 smtp.google.com."]},{"nameserver":"8.8.8.8","zone":".com","type":"A","domain":"google","fqdn":"google.com","records":["142.250.150.138","142.250.150.113","142.250.150.102","142.250.150.139","142.250.150.100","142.250.150.101"]}],"errors":[]}
```

## function json_to_yaml

Transform json output to yaml.

**Input**:
1. Json formatted lookup result (format_json)

**Output**: aggregated lookup results in yaml format

### Examples:

#### 1. *Input*:
```
'{"data":[{"nameserver":"8.8.8.8","zone":"","type":"MX","domain":"google.com","fqdn":"google.com","records":["10 smtp.google.com."]},{"nameserver":"8.8.8.8","zone":".com","type":"A","domain":"google","fqdn":"google.com","records":["142.250.150.138","142.250.150.113","142.250.150.102","142.250.150.139","142.250.150.100","142.250.150.101"]},{"nameserver":"8.8.8.8","zone":".com","type":"A","domain":"www.example","fqdn":"www.example.com","records":["www.example.com-v4.edgesuite.net.","a1422.dscr.akamai.net.","2.16.53.33","2.16.53.27"]},{"nameserver":"8.8.8.8","zone":".com","type":"A","domain":"github","fqdn":"github.com","records":["140.82.121.3"]}],"errors":[]}'
```

*Output*:
```
data:
  - nameserver: 8.8.8.8
    zone: ''
    type: MX
    domain: google.com
    fqdn: google.com
    records:
      - 10 smtp.google.com.
  - nameserver: 8.8.8.8
    zone: .com
    type: A
    domain: google
    fqdn: google.com
    records:
      - 142.250.150.138
      - 142.250.150.113
      - 142.250.150.102
      - 142.250.150.139
      - 142.250.150.100
      - 142.250.150.101
  - nameserver: 8.8.8.8
    zone: .com
    type: A
    domain: www.example
    fqdn: www.example.com
    records:
      - www.example.com-v4.edgesuite.net.
      - a1422.dscr.akamai.net.
      - 2.16.53.33
      - 2.16.53.27
  - nameserver: 8.8.8.8
    zone: .com
    type: A
    domain: github
    fqdn: github.com
    records:
      - 140.82.121.3
errors: []
```
