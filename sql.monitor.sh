#!/bin/bash
# script: sql.monitor.sh
# author: Richard K @ www.rkkoranteng.com
# description: alert when there's a long running sql
# usage: $0 <<elapse time>

# check syntax
if [ $# -ne 1 ]
then
 echo -e "\nUsage: $0 <elapse time>\n\n   <elapse time> = sla for long running sql in minutes\n"
 exit 1;
fi

# declare variables
source ~/.bash_profile
criticalElapsedTime=$1
mailAddress='richard@rkkoranteng.com'
logFile='/tmp/monitor_sql.log'

# clean old logs
if [ -f '${logFile}' ]
then
 rm -fr ${logFile}
fi

# check for long running sql
sqlplus -S -L / as sysdba << ENDSQL
set feedback off
set pages 0
set echo off
set pagesize 500
set linesize 500
set long 99999999
set newpage none
spool ${logFile}
select sql_id, first_load_time, last_load_time, round(elapsed_time * 0.000000017) as elapsed_minutes from v\$sql where round(elapsed_time * 0.000000017) >= ${criticalElapsedTime};
spool off
ENDSQL

# send mail alert
if [ "`wc -l ${logFile} | awk '{print $1}'`" -gt 0 ]
then
  mailx -a ${logFile} -s 'CRITICAL: `hostname` : ${ORACLE_SID} - long running SQL' ${mailAddress} < /dev/null
fi
