#!/bin/bash

# if running the kdb+tick example, change these to full paths
# some of the kdb+tick processes will change directory, and these will no longer be valid

# get absolute path to setenv.sh directory
if [ "-bash" = $0 ]; then
  dirpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  dirpath="$(cd "$(dirname "$0")" && pwd)"
fi


export TORQHOME=${dirpath}
export TORQAPPHOME=${TORQHOME}
export TORQDATAHOME=${TORQHOME}
export KDBCONFIG=${TORQHOME}/config
export KDBCODE=${TORQHOME}/code
export KDBLOG=${TORQDATAHOME}/logs
export KDBHTML=${TORQHOME}/html
export KDBLIB=${TORQHOME}/lib
export KDBHDB=${TORQDATAHOME}/hdb
export TORQTAQTEMPDB=${TORQDATAHOME}/tempdb
export TORQTAQMERGED=${TORQDATAHOME}/merged
export TORQTAQFILEDROP=${TORQDATAHOME}/filedrop
export KDBTESTS=${TORQHOME}/tests
# set rlwrap and qcon paths for use in torq.sh qcon flag functions
export RLWRAP="rlwrap"
export QCON="qcon"

# set the application specific configuration directory
export KDBAPPCONFIG=${TORQAPPHOME}/appconfig
export KDBAPPCODE=${TORQAPPHOME}/code
# set KDBBASEPORT to the default value for a TorQ Installationr
export KDBBASEPORT=1259
# set TORQPROCESSES to the default process csv
export TORQPROCESSES=${KDBAPPCONFIG}/process.csv
