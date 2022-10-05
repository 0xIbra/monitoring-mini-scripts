#!/usr/bin/env bash

function string_contains() {
    needle=$1
    haystack=$2

    if grep -q "$needle" <<< "$haystack"; then
        echo "1"
    else
        echo "0"
    fi
}