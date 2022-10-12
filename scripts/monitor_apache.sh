#!/usr/bin/env bash

WORK_DIR="$(dirname "$(realpath "$0")")"

source $WORK_DIR/utils.sh
source $WORK_DIR/slack.sh

DOWNTIME_BEFORE_RESTART=$DOWNTIME_BEFORE_RESTART
if [[ -z "${DOWNTIME_BEFORE_RESTART}" ]]; then
  DOWNTIME_BEFORE_RESTART=900
fi

APACHE_MONITOR_SLACK_HOOK=$APACHE_MONITOR_SLACK_HOOK
if [[ -z "${APACHE_MONITOR_SLACK_HOOK}" ]]; then
  # if slack env var is undefined, check if defined in file ".env"

  if [ -e "$WORK_DIR/.env" ]; then
    source $WORK_DIR/.env
  fi

fi

function restart_successful_handler() {
  text="apache restarted successfully"
  log "${text}"

  if [[ $(string_contains "https://" "$APACHE_MONITOR_SLACK_HOOK") == "1" ]]; then
    slack_notification "$APACHE_MONITOR_SLACK_HOOK" "[$(hostname)]$(date_prefix) $text"
  fi
}

function restart_failed_handler() {
  text="could not restart apache"
  log "$text"

  if [[ $(string_contains "https://" "$APACHE_MONITOR_SLACK_HOOK") == "1" ]]; then
    # multi-line log with contents of `service apache2 status` as a code block below
    text="[$(hostname)]$(date_prefix) $text\n\napache2 status:\n\`\`\` $(service apache2 status) \`\`\`"

    slack_notification "$APACHE_MONITOR_SLACK_HOOK" "$text"
  fi
}

if [[ $(is_running apache2) == "0" ]]; then
    # apache down, verify downtime

    # retrieving downtime from service status
    now=$(date "+%F %T")
    downdate=$(service apache2 status | grep -oP 'since ([a-zA-Z]+) (.*) ([a-zA-Z]+);' | awk '{print $3,$4;}')

    # check if downtime available, if not, then wait 10 minutes and try to restart apache
    # waiting 10 minutes to avoid, interrupting ssl update certbot process which requires that apache be down
    if [[ $downdate == "" ]]; then
      log "apache downtime unavailable, waiting 10 minutes before attempting to restart"

      sleep 600

      # check again if apache still down
      if [[ $(is_running apache2) == "0" ]]; then
        # apache still down after 10 minutes
        log "apache is still down after 10 minutes of waiting, attempting to restart..."
        response=$(service apache2 restart &> /dev/null)

        sleep 10

        if [[ $(is_running apache2) == "1" ]]; then
          restart_successful_handler
        else
          restart_failed_handler
        fi

      else
        log "apache up on it's own after waiting a bit, no action to take."
      fi

    fi

    # if here, downtime was retrieved

    now_timestamp=$(date -d "$now" '+%s')
    down_timestamp=$(date -d "$downdate" '+%s')

    downtime=$(( ( $now_timestamp - $down_timestamp ) ))
    downtime_mins=$(($downtime / 60))

    down_text="${downtime_mins} mins"
    if [[ ($downtime_mins < 1) ]]; then
      down_text="${downtime} secs"
    fi

    # if downtime > 15 mins, then restart apache
    if [[ $downtime -gt $DOWNTIME_BEFORE_RESTART ]]; then
      log "apache been down for $down_text, attempting to restart..."
      response=$(service apache2 restart &> /dev/null)

      # wait for 10 seconds before proceeding
      sleep 10

      # check if apache is now up
      if [[ $(is_running apache2) == "1" ]]; then
        # apache is now up
        restart_successful_handler
      else
        # restart did not work, apache still down
        restart_failed_handler
      fi

    else
      # apache been down for less than $DOWNTIME_BEFORE_RESTART (default: 15 mins)
      log "apache has been down only for $down_text, no action taken."
    fi

fi
