#!/bin/bash
# script: renamePDB.sh v1
# author: Richard K @ www.rkkoranteng.com
# desc: simplify the process for renaming an Oracle PDB
# last modified: 6/01/2019

# example: ./pdb.rename.sh {CDB NAME} {OLD PDB NAME} {NEW PDB NAME}

if [ $# -ne 3 ]
then
  echo -e "\nUsage: $0 [cdb] [old pdb] [new pdb]\n"
  exit 1;
fi

source ~/.bash_profile

ORACLE_SID=$1
oldPDB=$2
newPDB=$3

# check pdb name conflict
checkPDBName=`sqlplus -L -S / as sysdba<<ENDSQL
  set heading off;
  set feedback off;
  set newpage none;
  select name from v\\$containers where name='${newPDB}';
ENDSQL`
if [ "${checkPDBName}" == "" ]
then
  # rename pdb
  sqlplus -S -L / as sysdba << ENDSQL
  alter pluggable database ${oldPDB} close immediate;
  alter pluggable database ${oldPDB} open restricted;
  alter session set container=${oldPDB};
  alter pluggable database ${oldPDB} rename global_name to ${newPDB};
  alter pluggable database close immediate;
  alter pluggable database open;
  EXIT;
ENDSQL
  echo "${oldPDB} has been successfully renamed to ${newPDB}"
else
  # pdb name conflict
  echo "PDB name '${oldPDB}' already exist in this CDB. Choose a different PDB name."
  exit 1;
fi
