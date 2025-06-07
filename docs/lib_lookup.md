# lib/lookup.sh

## function parse_nameservers

Parses .nameservers list from json formatted configuration file.

**Input**:
1. Json formatted config.
```
{"output":"yaml","nameservers":["8.8.8.8","127.0.0.1"],"lookup":[{"type":"MX","domains":["google.com","example.com"]},{"zone":"com","domains":["google","www.example"]}]}
```

**Output**: array of nameservers
```
8.8.8.8 127.0.0.1
```

## function parse_lookup_zone

Parses .lookup[].zone, adds . in front of zone name.

If value is null, replaces with empty string.

**Input:**
1. Json formatted .lookup[] item

**Output**: zone (string)

### Examples

#### 1. *Input*:
```
{"type":"MX","domains":["google.com","example.com"]}
```

*Output*:
```
```

#### 2. *Input*:
```
{"zone":"com","domains":["google","www.example"]}
```

*Output*:
```
.com
```

## function parse_lookup_record_type

Parses .lookup[].type.

If value is null, replaces with A, so default lookup is A record.

**Input**:
1. Json formatted .lookup[] item

**Output**: DNS record type (string)

### Examples:

#### 1. *Input*:
```
{"type":"MX","domains":["google.com","example.com"]}
```

*Output*:
```
MX
```

#### 2. *Input*:
```
{"zone":"com","domains":["google","www.example"]}
```

*Output*:
```
A
```

## function parse_lookup_domains

Parses .lookup[].domains list.

**Input**:
1. Json formatted .lookup[] item

**Output**: array of domains

### Examples:

#### 1. *Input*:
```
{"type":"MX","domains":["google.com","example.com"]}
```

*Output*:
```
google
www.example
```

#### 2. *Input*:
```
{"zone":"com"}
```

*Output*:
```
jq: error (at <stdin>:1): Cannot iterate over null (null)
```

## function lookup_domain

Performs DNS lookup with dig.

**Input**:
1. Nameserver (string)
2. Domain (string)
3. Zone (string)
4. Record type (string)

**Output**: answer section in short format (array)

### Examples

#### 1. *Input*:
```
8.8.8.8 google.com '' MX
```

*Output*:
```
10 smtp.google.com.
```

#### 2. *Input*:
```
127.0.0.1 google.com '' MX
```

*Output*:
```
;; communications error to 127.0.0.1#53: connection refused
;; communications error to 127.0.0.1#53: connection refused
;; communications error to 127.0.0.1#53: connection refused
;; no servers could be reached
```

#### 3. *Input*:
```
8.8.8.8 www.example .com A
```

*Output*:
```
www.example.com-v4.edgesuite.net.
a1422.dscr.akamai.net.
2.16.53.33
2.16.53.27
```
