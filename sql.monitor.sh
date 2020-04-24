#!/bin/bash
# script: sql.monitor.sh
# version: 1.0.1
# author: Richard K @ www.rkkoranteng.com
# description: alert when there's a long running sql within the last hour
# usage: $0 <elapse_time>
#
# CHANGE LOG:
# -----------
# 04/22/2020 - initial script devlopment
# 04/24/2020 - bug fix: unable to get accurate timing for long running sql
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
if [ $# -ne 1 ]
then
 echo -e "\nUsage: $0 <elapse_time>\n\n   <elapse_time> = sla for long running sql in hours\n"
 exit 1;
fi

# declare variables
source ~/.bash_profile
criticalElapsedTime=$1
mailAddress='richard@rkkoranteng.com'
logFile='/tmp/monitor_sql.log'
exemptUser="'SYSTEM'"   #add users in single quoate delimited by comma

# clean old logs
if [ -f "${logFile}" ]
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
 select open_mode from v\$database;
 exit;
ENDSQL`
fi

if [ "$openMode" == "READ WRITE" ] || [ "$psCount" -gt 0 ]
then

 # check for long running sql
 sqlplus -S -L / as sysdba << ENDSQL
    set wrap off
  set feedback off
  set pages 0
  set echo off
  set pagesize 0
  set linesize 500
  set long 99999999
  set newpage none
  spool ${logFile}
  select
     stat.sql_id,
     rpad(parsing_schema_name,10) "USER",
     lops.opname "OPERATION",
     to_char(lops.start_time,'mm-dd-yy hh24:mi:ss') "START TIME",
     elapsed_time_total/3600000000 "ELAPSED TIME (HOUR)"
  from
     dba_hist_sqlstat  stat,
     dba_hist_sqltext  txt,
     dba_hist_snapshot ss,
     v\$session_longops lops
  where
     stat.sql_id = txt.sql_id
  and
     stat.dbid = txt.dbid
  and
     ss.dbid = stat.dbid
  and
     ss.instance_number = stat.instance_number
  and
     stat.snap_id = ss.snap_id
  and
     parsing_schema_name not in (${exemptUser})
  and
     ss.begin_interval_time >= sysdate-40
  and
     stat.elapsed_time_total/3600000000 > ${criticalElapsedTime}
  and
     last_update_time between (sysdate - (60/(24*60))) and (sysdate - (1/(24*60)))
  order by
     elapsed_time_total desc;
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
