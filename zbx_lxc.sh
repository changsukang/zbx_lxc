#!/bin/bash

. $(dirname $0)/env.sh # loads zsender, zserver and zport

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
    cpusec=$(echo "scale=9; $(lxc-cgroup -n $c 'cpuacct.usage')/1000/1000/1000" | bc -l)
    echo "$zsender lxc.cpuacct.usage[$c] $cpusec" >> $cgroup

    memlimit=$(echo "scale=9; $(lxc-cgroup -n $c 'memory.limit_in_bytes')/1024/1024/1024" | bc -l)
    echo "$zsender lxc.memory.limit_in_bytes[$c] $memlimit" >> $cgroup
    swlimit=$(echo "scale=9; $(lxc-cgroup -n $c 'memory.memsw.limit_in_bytes')/1024/1024/1024" | bc -l)
    echo "$zsender lxc.memory.memsw.limit_in_bytes[$c] $swlimit" >> $cgroup
    
    memusage=$(echo "scale=9; $(lxc-cgroup -n $c 'memory.usage_in_bytes')/1024/1024/1024" | bc -l)
    cached=$(echo "scale=9; $(lxc-cgroup -n $c 'memory.stat' | grep 'total_cache' | cut -d' ' -f2)/1024/1024/1024" | bc -l)
    swusage=$(echo "scale=9; $(lxc-cgroup -n $c 'memory.memsw.usage_in_bytes')/1024/1024/1024" | bc -l)

    # calculate AVAILABLE memory/swap
    availmem=$(echo "scale=9; $memlimit-$memusage+$cached" | bc -l)
    echo "$zsender lxc.memory.avail_in_bytes[$c] $availmem" >> $cgroup
    mempercent=$(echo "scale=2; 100*$availmem/$memlimit" | bc -l)
    echo "$zsender lxc.memory.avail_in_percent[$c] $mempercent" >> $cgroup
    availsw=$(echo "scale=9; $swlimit-$swusage" | bc -l)
    echo "$zsender lxc.memory.memsw.avail_in_bytes[$c] $availsw" >> $cgroup
    swpercent=$(echo "scale=2; 100*$availsw/$swlimit" | bc -l)
    echo "$zsender lxc.memory.memsw.avail_in_percent[$c] $swpercent" >> $cgroup
done

zabbix_sender -vv -z $zserver -p $zport -i $cgroup
