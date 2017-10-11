#!/bin/bash
# autogit.sh - automatically monitor directories from supplied config file and auto commit to GIT on configured basis
#
#

REPOS=${1}
INTERVAL=60
LOG_LOCATION=${2}

while true
do
  for i in $REPOS
  do
    echo "checking REPO ${i}"
    GIT_DIFF=git diff ${i}
    if [ -z $GIT_DIFF ] 
    then
      echo "There is a diff!!"
      echo $GIT_DIFF
    fi
  done
  sleep $INTERVAL
done

