## Config format

Configuration file should be named `config.json` or `config.yaml`.

Default input is `config.json`, then try `config.yaml`.

YAML example:
```
---
output: json            # Values: json, pretty_json. Default is json. Optional. 
nameservers:            # List of nameservers. Required.
  - 8.8.8.8
  - 1.1.1.1
lookup:                # List of records. Required.
  - type: A             # Record type. Default is A. Optional.
    zone: com           # Zone. Optional.
    domains:            # List of domains of specified zones. Required.
      - google
      - www.example
  - type: MX            # Record type. Default is A. Optional.
    domains:            # List of domains in FQDN format (no zone specified). Required.
      - google.com
      - example.com
```

JSON example:
```
{
  "output": "json",
  "nameservers": [
    "8.8.8.8",
    "1.1.1.1"
  ],
  "lookup": [
    {
      "type": "A",
      "zone": "com",
      "domains": [
        "google",
        "www.example"
      ]
    },
    {
      "type": "MX",
      "domains": [
        "google.com",
        "example.com"
      ]
    }
  ]
}
```
