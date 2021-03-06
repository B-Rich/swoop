#!/bin/bash

# A script to make executing a single command on multiple servers a little easier
# A work in progress by Chris Hidalgo <zully_1@yahoo.com>

# Make sure the user supplies a command
if [ -z $1 ]; then
    echo "Usage: swoop <command>"
    exit
fi

# If any of the common server lists exist, then use them
if [ -f /etc/lsyncd-servers.conf ]; then
    cp /etc/lsyncd-servers.conf /tmp/swoop-iterables
elif [ -f /etc/lsyncd/servers.conf ]; then
    cp /etc/lsyncd/servers.conf /tmp/swoop-iterables
fi

# If unable to find a server list, then attempt to grep out ip list form most recently modified common config
if [ ! -f /tmp/swoop-iterables ]; then
    if [ /etc/lsyncd.lua -nt /etc/lsyncd.conf ]; then
        if [ /etc/lsyncd.lua -nt /etc/lsyncd/lsyncd.conf ]; then
            filename=/etc/lsyncd.lua
        fi
    elif [ /etc/lsyncd.conf -nt /etc/lsyncd.lua ]; then
        if [ /etc/lsyncd.conf -nt /etc/lsyncd/lsyncd.conf ]; then
            filename=/etc/lsyncd.conf
        fi
    elif [ /etc/lsyncd/lsyncd.conf -nt /etc/lsyncd.conf ]; then
        if [ /etc/lsyncd/lsyncd.conf -nt /etc/lsyncd.lua ]; then
            filename=/etc/lsyncd/lsyncd.conf
        fi
    fi
    # If a filename variable was set and it contains an IP, then grep out the IP list
    if [ ! -z $filename ]; then
        exists=`egrep -v '^#' $filename | grep -c '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
        if [ $exists -gt 0 ]; then
            egrep -v '^#' $filename | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' > /tmp/swoop-iterables
        fi
    fi
fi

# If this file doesn't exist at this point, terminate.
if [ ! -f /tmp/swoop-iterables ]; then
    echo "Error: cannot locate an IP list to iterate over"
    exit 1
fi

echo "-+- Executing [$@] on local server -+-"
$@

for ip in `cat /tmp/swoop-iterables`; do
    echo "-+- Executing [$@] on $ip -+-"
    ssh root@$ip $@
done < /tmp/swoop-iterables

rm -f /tmp/swoop-iterables
