# lib/configuration.sh

Library for handle configuration file.

## function import_config

Imports json or yaml formatted configuration file. 

Configuration file should be named config.json or config.yaml. 

Exits if config does not exist or invalid (can not be parsed by jq or yq).

**Input**:
1. Script directory. Defined with `SCRIPT_DIR="${0%/*}"` in main script.

**Output**: json formatted config
```
{"output":"yaml","nameservers":["8.8.8.8","127.0.0.1"],"lookup":[{"type":"MX","domains":["google.com","example.com"]},{"zone":"com","domains":["google","www.example"]}]}
```

### Exceptions

If config is not valid
```
jq: parse error: Unfinished JSON term at EOF at line 23, column 0
++ return 1
```

If config not found
```
Configuration file config.json/config.yaml not found.
++ return 1
```

## function define_output

Checks if output format is defined and allowed: `allowed_format=(json pretty_json yaml)`

Sets json if output format is not defined.

Exits if output format is not allowed.

**Input**:
1. Json formatted config

**Output**: result output format (string)

### Examples

#### 1. *Input*:
```
{"output":"yaml","nameservers":["8.8.8.8","127.0.0.1"],"lookup":[{"type":"MX","domains":["google.com","example.com"]},{"zone":"com","domains":["google","www.example"]}]}
```

*Output*:
```
yaml
```

#### 2. *Input*:
```
{"output":"xml","nameservers":["8.8.8.8","127.0.0.1"],"lookup":[{"type":"MX","domains":["google.com","example.com"]},{"zone":"com","domains":["google","www.example"]}]}'
```

*Output*:
```
Format xml is not allowed
++ return 1
```
