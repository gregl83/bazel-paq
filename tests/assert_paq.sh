#!/usr/bin/env bash
set -euo pipefail
[[ "$#" -eq 1 ]] || { echo "Expected one manifest path"; exit 1; }
exec 3< "$1"
IFS= read -r -d '' expected_count <&3
IFS= read -r -d '' actual_count <&3
[[ "$expected_count" -eq "$actual_count" ]] || { echo "Unexpected number of hash files"; exit 1; }
expected_paths=()
expected_hashes=()
actual_paths=()
for ((i = 0; i < expected_count; i++)); do
    IFS= read -r -d '' path <&3
    IFS= read -r -d '' hash <&3
    expected_paths+=("$path")
    expected_hashes+=("$hash")
done
for ((i = 0; i < actual_count; i++)); do
    IFS= read -r -d '' path <&3
    actual_paths+=("$path")
done
exec 3<&-
for ((i = 0; i < expected_count; i++)); do
    path="${expected_paths[$i]}"
    hash="${expected_hashes[$i]}"
    found=false
    for actual in "${actual_paths[@]}"; do
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
