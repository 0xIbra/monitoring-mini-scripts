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

function date_prefix() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")]"
}

function log() {
    log_text=$1

    echo "$(date_prefix) ${log_text}"
}

function log_with_host() {
    log_text=$1

    echo "[$(hostname)]$(log_prefix) $log_text"
}
