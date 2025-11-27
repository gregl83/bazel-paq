#!/bin/bash

actual="$(cat "$1")"
expected="$2"

if [ "$actual" != "$expected" ]; then
    echo "Expected: $expected"
    echo "Actual: $actual"
    exit 1
fi
