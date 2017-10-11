#!/bin/bash
# autogit.sh - automatically monitor directories from supplied config file and auto commit to GIT on configured basis
#
#

REPOS=${1}
INTERVAL=30
LOG_LOCATION=${2}

while true
do
  for i in $REPOS
  do
    echo "checking REPO ${i}"
    GIT_DIFF=$(git diff ${i})
    if [ 0 -lt $(echo $GIT_DIFF|wc -w) ] 
    then
      echo "There is a diff!!"
      echo $GIT_DIFF
      git commit -a -m "auto commit"
      echo "Complete"
    else
      echo "Nothing to commit
    fi  
  done
  sleep $INTERVAL
done

