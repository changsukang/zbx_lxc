# Introduction
This is a bash script to monitor Linux Containers (LXC) with Zabbix.

First, the script uses "lxc-ls" to discover active containers. 
Second, it uses "lxc-cgroup" to get CPU, Memory and Swap information from cgroup for each active container.
Last, it sends the information to Zabbix server with "zabbix_sender."

# How to use

## Download in an LXC running host
```
# cd /directory/to/install/
# git clone https://github.com/changsukang/zbx_lxc.git
```
You can see /directory/to/install/zbx_lxc.

## Import a template and link it to a LXC running host
In the directory you download, there is "zbx_lxc_templates.xml." 
Import it to your Zabbix server and link it to your LXC running host.
If you use swap in the host and your containers, you have to enable item prototypes related to swap: \*.memsw.\*.

## Copy env.sh.example to env.sh and edit it
```
zsender="lxc.host.com"      # lxc host registered in Zabbix
zserver="zabbix.server.com" # Zabbix server or proxy
zport="10051"               # Zabbix server/proxy port number
```
Copy or move env.sh.example to env.sh and edit it based on your environment. 
"zsender" must be the name you set up for the LXC running host in your Zabbix server.

## Test
```
# /directory/to/install/zbx_lxc/zbx_lxc.sh
```
Check if "lxc-ls", "lxc-cgroup" and "zabbix_sender" are in PATH and if you have permission to run them.

## Run every minute
```
# /directory/to/install/zbx_lxc/run.sh
```
The script loops every one minute to run "zbx_lxc.sh" described above.
