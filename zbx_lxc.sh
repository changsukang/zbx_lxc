#!/bin/bash

. $(dirname $0)/env.sh # loads zsender, zserver and zport

objects="cpuacct.usage"

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
    for o in $objects; do
	echo "$zsender lxc.$o[$c] $(echo $(lxc-cgroup -n $c $o)/1000/1000/1000 | bc -l)" >> $cgroup
    done
done

zabbix_sender -vv -z $zserver -p $zport -i $cgroup
