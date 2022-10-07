Monitoring bash scripts
=======================

> simple bash scripts that monitor a few **systemd** services. 


----------------------------------------------------------------------

##### Monitor Apache http server
file: `scripts/monitor_apache.sh`  

Checks if the `apache2` service is running, if not and if has crashed, attempts to restart it after period of time which can be defined with the `DOWNTIME_BEFORE_RESTART` environment variable (default: **900 secs**).

You can also configure a slack notification by defining the variable `APACHE_MONITOR_SLACK_HOOK`.  
If defined, the script will send a notification message with details in case of errors.


When configuring this script with a cron job, don't forget to use **flock** to avoid double executions.  
**Example:**
```conf
5/* * * * * flock -n /tmp/apache_monitor.lock -c "/path/to/scripts_dir/apache_monitor.sh"
```

**flock** ensure single execution if the script takes too long.

----------------------------------------------------------------------
