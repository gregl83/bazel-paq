#!/usr/bin/env bash
set -euo pipefail
expected=()
while [[ "$1" != -- ]]; do
    expected+=("$1")
    shift
done
shift
[[ "${#expected[@]}" -eq "$#" ]] || { echo "Unexpected number of hash files"; exit 1; }
for entry in "${expected[@]}"; do
    path="${entry%%=*}"
    hash="${entry#*=}"
    found=false
    for actual in "$@"; do
        if [[ "$actual" == "$path" || "$actual" == */"$path" ]]; then
            found=true
            [[ "$(cat "$actual")" == "\"$hash\"" ]] || {
                echo "Wrong hash for $path: expected $hash, got $(cat "$actual")"
                exit 1
            }
        fi
    done
    $found || { echo "Missing hash: $path"; exit 1; }
done
