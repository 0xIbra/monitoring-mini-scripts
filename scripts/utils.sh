#!/usr/bin/env bash

# checks if a string contains another given string
function string_contains() {
    needle=$1
    haystack=$2

    if grep -q "$needle" <<< "$haystack"; then
        echo "1"
    else
        echo "0"
    fi
}

# function checks if a given service is running or not
function is_running() {
    servicename=$1
    
    servstat=$(service $servicename status)
    if [[ $(string_contains "active (running)" "$servstat") == "1" ]]; then
      echo "1"
    else
      echo "0"
    fi
}

# returns a formatted date string for logging
function date_prefix() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")]"
}

# logs text with date time information
function log() {
    log_text=$1

    echo "$(date_prefix) ${log_text}"
}

# logs text with date time and host information
function log_with_host() {
    log_text=$1

    echo "[$(hostname)]$(log_prefix) $log_text"
}
