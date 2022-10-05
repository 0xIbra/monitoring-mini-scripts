#!/usr/bin/env bash

function is_curl_installed() {
    # which_path=$(which curl)
    if which curl &> /dev/null; then
        echo "1"
    else
        echo "0"
    fi
}

if [[ $(is_curl_installed) != "1" ]]; then
    echo '"curl" package must be installed for this script to work.' && exit
fi

function slack_notification() {
    webhook=$1
    message=$2

    response=$(curl -Li -o /dev/null -sw '%{http_code}' --location --request POST "${webhook}" --header 'Content-Type: application/json' --data-raw "{\"text\": \"${message}\"}")
    if [[ $response != '200' ]]; then
        echo "[error] could not send slack message. http_code: ${response}"
    fi
}
