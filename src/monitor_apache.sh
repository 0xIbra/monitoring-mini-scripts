#!/usr/bin/env bash

source utils.sh
source slack.sh

DOWNTIME_BEFORE_RESTART=$DOWNTIME_BEFORE_RESTART
if [[ -z "${DOWNTIME_BEFORE_RESTART}" ]]; then
  DOWNTIME_BEFORE_RESTART=900
fi

function is_running() {
    servicename=$1
    
    servstat=$(service $servicename status)
    if [[ $servstat == *"active (running)"* ]]; then
      echo "1"
    else echo "0"
    fi
}

if [[ $(is_running apache2) == "0" ]]; then
    # apache down, verify downtime

    now=$(date "+%F %T")
    downdate=$(service apache2 status | grep -oP 'since ([a-zA-Z]+) (.*) ([a-zA-Z]+);' | awk '{print $3,$4;}')

    now_timestamp=$(date -d "$now" '+%s')
    down_timestamp=$(date -d "$downdate" '+%s')

    downtime=$(( ( $now_timestamp - $down_timestamp ) ))
    downtime_mins=$(($downtime / 60))

    down_text="${downtime_mins} mins"
    if [[ ($downtime_mins < 1) ]]; then
      down_text="${downtime} secs"
    fi


    # if downtime > 15 mins, then restart apache
    if [[ downtime > 900 ]]; then
      echo "apache been down for $down_text, attempting to restart..."
      response=$(service apache2 restart &> /dev/null)
      
      if [[ $(is_running apache2) == "0" ]]; then
        text="apache restarted successfully"
        echo $text

        if [[ $(string_contains "https://" "$MONITORING_SLACK_WEBHOOK") == "1" ]]; then
          slack_notification "$MONITORING_SLACK_WEBHOOK" "$text"
        fi

      else echo "[error] could not restart apache"
      fi

    fi


fi