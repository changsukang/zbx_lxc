#!/bin/bash

. $(dirname $0)/env.sh # loads zsender, zserver and zport

objects=( \
	'cpuacct.usage' \
	'memory.usage_in_bytes' \
	'memory.limit_in_bytes' \
	'memory.memsw.usage_in_bytes' \
	'memory.memsw.limit_in_bytes' \
)

discovery="$(dirname $0)/discovery"
cgroup="$(dirname $0)/cgroup"

active=( $(lxc-ls --active) ) # build a list with active containers

echo -n "$zsender lxc.discovery " > $discovery
echo -n "{ \"data\": [ " >> $discovery
for (( i=0; i<${#active[@]}; i++ )); do
    echo -n "{ \"{#LXCNAME}\":\"${active[$i]}\" }" >> $discovery
    if (( i < ${#active[@]}-1 )); then
	echo -n ", " >> $discovery
    fi
done
echo " ] }" >> $discovery

zabbix_sender -vv -z $zserver -p $zport -i $discovery

echo -n "" > $cgroup 
for c in ${active[@]}; do
    for o in ${objects[*]}; do
	echo -n "$zsender lxc.$o[$c] " >> $cgroup
	if [ "$o" == "cpuacct.usage" ]; then
	    value=$(echo "scale=9; $(lxc-cgroup -n $c $o)/1000/1000/1000" | bc -l)
	else
	    value=$(echo "scale=9; $(lxc-cgroup -n $c $o)/1024/1024/1024" | bc -l)
	    if [ "$o" == "memory.usage_in_bytes" ]; then
		memusage=$value
	    elif [ "$o" == "memory.limit_in_bytes" ]; then
		memlimit=$value
	    elif [ "$o" == "memory.memsw.usage_in_bytes" ]; then
		swusage=$value
	    elif [ "$o" == "memory.memsw.limit_in_bytes" ]; then
		swlimit=$value
	    fi
	fi
	echo $value >> $cgroup
    done
    # calculate percentage
    mempercent=$(echo "scale=2; 100*$memusage/$memlimit" | bc -l)
    echo "$zsender lxc.memory.usage_in_percent[$c] $mempercent" >> $cgroup
    swpercent=$(echo "scale=2; 100*$swusage/$swlimit" | bc -l)
    echo "$zsender lxc.memory.memsw.usage_in_percent[$c] $swpercent" >> $cgroup
done

zabbix_sender -vv -z $zserver -p $zport -i $cgroup
