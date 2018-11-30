#!/bin/bash

if [ -f $(dirname $0)/run.lock ]; then
    echo "already running"
    exit 1 
fi

touch $(dirname $0)/run.lock

nohup bash -c "while true; do $(dirname $0)/zbx_lxc.sh > $(dirname $0)/zbx_lxc.log 2>&1; sleep 60s; done" &

exit 0
