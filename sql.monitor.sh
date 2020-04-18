#!/bin/bash
# script: sql.monitor.sh
# author: Richard K @ www.rkkoranteng.com
# description: alert when there's a long running sql within the last hour
# usage: $0 <elapse time>  <email>
#
# SUMMARY OD STEPS:
# -----------------
#  - check syntax
#  - declare variables
#  - clean old logs
#  - check db availability
#  - check for long running sql
#  - send mail alert

# check syntax
if [ $# -ne 2 ]
then
 echo -e "\nUsage: $0 <elapse time>\n\n   <elapse time> = sla for long running sql in minutes\n   <email> = alert email address\n"
 exit 1;
fi

# declare variables
source ~/.bash_profile
criticalElapsedTime=$1
mailAddress=$2
logFile='/tmp/monitor_sql.log'

# clean old logs
if [ -f '${logFile}' ]
then
 rm -fr ${logFile}
fi

# check db availability
psCount=`ps -ef | grep smon | grep -v 'grep' | grep $ORACLE_SID | wc -l`

if [ "$psCount" -gt 0 ]
then
 openMode=`sqlplus -S -L / as sysdba << ENDSQL
 set feedback off
 set hea off pages 0
 set echo off
 set pagesize 500
 set linesize 500
 set long 99999999
 set newpage none
 column open_mode format a50
 select open_mode from v\\$database;
 exit;
ENDSQL`
fi

if [ "$openMode" == "READ WRITE" ] || [ "$psCount" -gt 0 ]
then

 # check for long running sql
 sqlplus -S -L / as sysdba << ENDSQL
  set feedback off
  set pages 0
  set echo off
  set pagesize 500
  set linesize 500
  set long 99999999
  set newpage none
  col opname format a45
  col username format a25
  col machine format a35
  spool ${logFile}
  select a.sql_id,a.opname,a.username,to_char(a.start_time,'mm-dd-yy hh24:mi:ss') as start_time,round(a.elapsed_seconds/60) as elapsed_minutes,b.program,b.machine
   from v\$session_longops a, v\$session b
  where
   program in ('SQL Developer')
   and round(a.elapsed_seconds/60) >= ${criticalElapsedTime}
   and last_update_time between (sysdate - (60/(24*60))) and (sysdate - (5/(24*60)))
  /
  spool off
  exit;
ENDSQL

else

 # db not available to perform query
 echo -e "\nError: database '$ORACLE_SID' is not available for this operation\n"
 exit 1;
fi

# send mail alert
if [ "`wc -l ${logFile} | awk '{print $1}'`" -gt 0 ]
then
  mailx -a ${logFile} -s 'CRITICAL: `hostname` : ${ORACLE_SID} - long running SQL' ${mailAddress} < /dev/null
fi
