#!/bin/bash
# script: getPDB.sh v1
# author: Richard K @ www.rkkoranteng.com
# desc: simplify the search for a PDB across several CDB's
# last modified: 5/4/2019 

# assumed that ORACLE_SID and ORACLE_HOME are set in bash_profile
. ~/.bash_profile

# usage
if [ $# -ne 1 ]; then
  echo "Usage: $0 pdb"
  exit
fi

script_dir="$( cd "$( dirname "$0" )" && pwd )"

# perform search for pdb
cat ${script_dir}/targets | grep -v '#' | while read VAR1 VAR2 VAR3
do
  host=${VAR1}
  sid=${VAR2}
  pswd=${VAR3}

  get_pdb=`sqlplus -L -S system/${pswd}@${host}/${sid}<<ENDSQL
  set heading off;
  set feedback off;
  set newpage none;
  select name from v\\$containers where name like '%${1}%';
ENDSQL`
  if [ "${get_pdb}" != "" ]
  then
    echo "${host} contains a pdb called ${get_pdb}"
  fi
done
