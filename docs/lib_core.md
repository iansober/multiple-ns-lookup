# lib/core.sh

Contains mostly used functions.

## function fail_if_empty

Checks if input is empty. Returns 1 if empty, 0 if not empty.

### Examples:

#### 1. *Input*:
```
'8.8.8.8 1.1.1.1 127.0.0.1'
```

*Output*:
```
+ return 0
```

#### 2. *Input*:
```
''
```

*Output*:
```
+ return 1
```

## function dns_lookup

Performs DNS lookup with dig.

**Input**:
1. Nameserver (string)
2. Domain (string)
3. Zone (string)
4. Record type (string)

**Output**: answer section in short format

### Examples:

#### 1. *Input*:
```
1.1.1.1
```

*Output*:
```
'a.root-servers.net.
b.root-servers.net.
c.root-servers.net.
d.root-servers.net.
e.root-servers.net.
f.root-servers.net.
g.root-servers.net.
h.root-servers.net.
i.root-servers.net.
j.root-servers.net.
k.root-servers.net.
l.root-servers.net.
m.root-servers.net.'
```

#### 2. *Input*:
```
8.8.8.8 google .com A
```

*Output*:
```
142.250.150.102
142.250.150.101
142.250.150.139
142.250.150.113
142.250.150.100
142.250.150.138
```

#### 3. *Input*:
```
1.1.1.1 google.com '' MX
```

*Output*:
```
10 smtp.google.com.
```

## function json_parse

Parses json key or list.

**Input**:
1. Search path
2. Json to parse

**Output**: array or value

### Examples:

#### 1. *Input*:
```
.zone '{"zone":"com","domains":["google","www.example","github"]}'
```

*Output*:
```
com
```

#### 2. *Input*:
```
.type '{"zone":"com","domains":["google","www.example","github"]}'
```

*Output*:
```
null
```

#### 3. *Input*:
```
'.domains[]' '{"zone":"com","domains":["google","www.example","github"]}'
```

*Output*:
```
google www.example github
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

## function json_append_error

Formatting error messages to json with description and message keys.

**Input**:
1. Error description
2. Error message/stderr
3. Existing json array

**Output**: json formatted error array with appended item

### Examples:

#### 1. *Input*:
```
'Invalid nameserver name: 1277.0.0.1. Exclude 1277.0.0.1 from the nameservers list.' '' '[]'
```

*Output*:
```
[{"description":"Invalid nameserver name: 1277.0.0.1. Exclude 1277.0.0.1 from the nameservers list.","message":""}]
```

#### 2. *Input*:
```
'Error parsing domains list in item {"domains":[]}' '' '[{"description":"Invalid nameserver name: 1277.0.0.1. Exclude 1277.0.0.1 from the nameservers list.","message":""}]'
```

*Output*:
```
[{"description":"Invalid nameserver name: 1277.0.0.1. Exclude 1277.0.0.1 from the nameservers list.","message":""},{"description":"Error parsing domains list in item {\"domains\":[]}","message":""}]
```

## function json_append_array

Append item to existing array.

**Input**:
1. Item to append
2. Existing json array

**Output**: json array with appended item

### Examples:

#### 1. *Input*:
```
'{"datetime":"2025-06-12T17:35:28+00:00","nameserver":"8.8.8.8","zone":".google.com","domain":"mail","fqdn":"mail.google.com","type":"A","lookup":["216.58.211.5"]}' '[]'
```

*Output*:
```
[{"datetime":"2025-06-12T17:35:28+00:00","nameserver":"8.8.8.8","zone":".google.com","domain":"mail","fqdn":"mail.google.com","type":"A","lookup":["216.58.211.5"]}]
```

#### 2. *Input*:
```
'{"datetime":"2025-06-12T17:35:28+00:00","nameserver":"8.8.8.8","zone":".google.com","domain":"meet","fqdn":"meet.google.com","type":"A","lookup":["142.250.74.174"]}' '[{"datetime":"2025-06-12T17:35:28+00:00","nameserver":"8.8.8.8","zone":".google.com","domain":"mail","fqdn":"mail.google.com","type":"A","lookup":["216.58.211.5"]}]'
```

*Output*:
```
[{"datetime":"2025-06-12T17:35:28+00:00","nameserver":"8.8.8.8","zone":".google.com","domain":"mail","fqdn":"mail.google.com","type":"A","lookup":["216.58.211.5"]},{"datetime":"2025-06-12T17:35:28+00:00","nameserver":"8.8.8.8","zone":".google.com","domain":"meet","fqdn":"meet.google.com","type":"A","lookup":["142.250.74.174"]}]
```
