Monitoring bash scripts
=======================

> simple bash scripts that monitor a few **systemd** services. 


----------------------------------------------------------------------

##### Monitor Apache http server
file: `scripts/monitor_apache.sh`  

Checks if the `apache2` service is running, if not and if has crashed, attempts to restart it after period of time which can be defined with the `DOWNTIME_BEFORE_RESTART` environment variable (default: **900 secs**).

You can also configure a slack notification by defining the variable `MONITORING_SLACK_WEBHOOK`.  
If defined, the script will send a notification message with details in case of errors.


You can configure it to run with a **cron job** every x minutes.

----------------------------------------------------------------------
