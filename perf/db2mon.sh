#!/bin/sh

dbName=$1
monitorTime=$2
scriptRoot=`dirname $0`

# Remove any user settings
export DB2OPTIONS=

if [ -z "$dbName" ]
then
   echo Specify a database to connect to!
   echo
   echo "Usage: db2mon.sh <dbname> [interval]"
   echo
   echo If no interval is specified, the default delay will be used.
   echo An interval of zero allows the user to control when collection ends.
   exit 1
fi

if [ -n "$monitorTime" ]; then
  if [ $monitorTime -eq $monitorTime 2> /dev/null ]; then
    if [ $monitorTime -gt 0 ]; then
      echo Monitoring interval set to $monitorTime seconds
    elif [ $monitorTime -eq 0 ]; then
      echo Monitoring interval set to zero - press enter to end monitoring interval
    else
      echo Error: Monitoring interval $monitorTime is negative - only positive intervals are supported
      exit -1
    fi
  else
    echo Error: Monitoring interval $monitorTime does not appear to be a number
    exit -2
  fi
fi

echo Scripts should be found in $scriptRoot

db2 -v connect to $dbName
db2 -v create bufferpool db2monbp
db2 -v create user temporary tablespace db2montmptbsp bufferpool db2monbp

db2 +c -tvf $scriptRoot/db2monBefore.sql

# Earlier versions did not offer a easily changable monitor time
if [ -z "$monitorTime" ]; then
  db2 +c -tvf $scriptRoot/db2monInterval.sql
else
  if [ "$monitorTime" == "0" ]; then
    echo Hit enter to finish monitoring
    read string
  else
    sleep $monitorTime
  fi
fi

db2 +c -tvf $scriptRoot/db2monAfter.sql

db2 -v commit work
db2 -v connect reset
db2 -v connect to $dbName

db2 -v drop tablespace db2montmptbsp
db2 -v drop bufferpool db2monbp

db2 -v connect reset
