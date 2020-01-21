#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# Simple example:
#  * pktgen sending with single thread and single interface
#  * flow variation via random UDP source port
#
basedir=`dirname $0`
source ${basedir}/functions.sh
root_check_run_with_sudo "$@"

# Parameter parsing via include
# - go look in parameters.sh to see which setting are avail
# - required param is the interface "-i" stored in $DEV
source ${basedir}/parameters.sh
#
# Set some default params, if they didn't get set
#if [ -z "$DEST_IP" ]; then
#    [ -z "$IP6" ] && DEST_IP="198.18.0.42" || DEST_IP="FD00::1"
#fi
[ -z "$CLONE_SKB" ] && CLONE_SKB="0"
[ -z "$COUNT" ]   && COUNT="100000" # Zero means indefinitely

# Base Config
DELAY="0"        # Zero means max speed

# source port between min and max
SRC_MAC=0c:c4:7a:2a:7b:61
SRC_IP=10.10.1.2
DST_MAC=70:69:5a:48:02:73
DST_IP=10.10.1.4
UDP_SPORT=10000

if [ -z "$UDP_DPORT" ]; then
    UDP_DPORT=10002
fi

echo "Destination port: " $UDP_DPORT

[ -z "$SRC_MAC" ] && usage && err 2 "Must specify src_mac"
[ -z "$DST_MAC" ] && usage && err 2 "Must specify dst_mac"

# General cleanup everything since last run
# (especially important if other threads were configured by other scripts)
pg_ctrl "reset"

# Add remove all other devices and add_device $DEV to thread 0
thread=0
pg_thread $thread "rem_device_all"
pg_thread $thread "add_device" $DEV

# How many packets to send (zero means indefinitely)
pg_set $DEV "count $COUNT"

# Reduce alloc cost by sending same SKB many times
# - this obviously affects the randomness within the packet
pg_set $DEV "clone_skb $CLONE_SKB"

# Set packet size
pg_set $DEV "pkt_size $PKT_SIZE"

# Delay between packets (zero means max speed)
pg_set $DEV "delay $DELAY"

# Flag example disabling timestamping
pg_set $DEV "flag NO_TIMESTAMP"

# Source
pg_set $DEV "src_mac $SRC_MAC"
pg_set $DEV "src_min $SRC_IP"
#pg_set $DEV "src_max $SRC_IP"

# Destination
pg_set $DEV "dst_mac $DST_MAC"
pg_set $DEV "dst_min $DST_IP"
#pg_set $DEV "dst_max $DST_IP"

# UDP port src & destination
pg_set $DEV "udp_src_min $UDP_SPORT"
#pg_set $DEV "udp_src_max $UDP_SPORT"
pg_set $DEV "udp_dst_min $UDP_DPORT"
#pg_set $DEV "udp_dst_max $UDP_DPORT"

# start_run
echo "Running... ctrl^C to stop" >&2
pg_ctrl "start"
echo "Done" >&2

# Print results
echo "Result device: $DEV"
cat /proc/net/pktgen/$DEV
