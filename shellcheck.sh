#!/bin/bash

SCRIPT_DIR="${0%/*}"

while read -r shell_file; do
    shellcheck -x "$shell_file"
done < <(find "$SCRIPT_DIR" -iname "*.sh")