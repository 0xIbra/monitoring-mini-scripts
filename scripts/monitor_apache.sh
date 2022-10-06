#!/usr/bin/env bash

source utils.sh
source slack.sh

DOWNTIME_BEFORE_RESTART=$DOWNTIME_BEFORE_RESTART
if [[ -z "${DOWNTIME_BEFORE_RESTART}" ]]; then
  DOWNTIME_BEFORE_RESTART=900
fi

if [[ $(is_running apache2) == "0" ]]; then
    # apache down, verify downtime

    now=$(date "+%F %T")
    downdate=$(service apache2 status | grep -oP 'since ([a-zA-Z]+) (.*) ([a-zA-Z]+);' | awk '{print $3,$4;}')
    if [[ $downdate == "" ]]; then
      log "apache downtime unavailable, maybe it was stopped purposefully"
      exit
    fi


    now_timestamp=$(date -d "$now" '+%s')
    down_timestamp=$(date -d "$downdate" '+%s')

    downtime=$(( ( $now_timestamp - $down_timestamp ) ))
    downtime_mins=$(($downtime / 60))

    down_text="${downtime_mins} mins"
    if [[ ($downtime_mins < 1) ]]; then
      down_text="${downtime} secs"
    fi


    # if downtime > 15 mins, then restart apache
    if [[ $downtime > $DOWNTIME_BEFORE_RESTART ]]; then
      log "apache been down for $down_text, attempting to restart..."
      response=$(service apache2 restart &> /dev/null)

      # wait for 10 seconds before proceeding
      sleep 10

      # check if apache is now up
      if [[ $(is_running apache2) == "1" ]]; then
        # apache is now up
        text="apache restarted successfully"
        log "${text}"

        if [[ $(string_contains "https://" "$MONITORING_SLACK_WEBHOOK") == "1" ]]; then
          slack_notification "$MONITORING_SLACK_WEBHOOK" "[$(hostname)]$(date_prefix) $text"
        fi

      else
        # restart did not work, apache still down
        text="could not restart apache"
        log "$text"

        if [[ $(string_contains "https://" "$MONITORING_SLACK_WEBHOOK") == "1" ]]; then
          # multi-line log with contents of `service apache2 status` as a code block below
          text="[$(hostname)]$(date_prefix) $text\n\napache2 status:\n\`\`\` $(service apache2 status) \`\`\`"

          slack_notification "$MONITORING_SLACK_WEBHOOK" "$text"
        fi

      fi

    else
      # apache been down for less than $DOWNTIME_BEFORE_RESTART (default: 15 mins)

      log "apache has been down only for $down_text, no action taken."

    fi

fi
