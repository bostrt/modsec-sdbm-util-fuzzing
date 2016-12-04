#!/bin/bash
source include.sh

if ! which coredumpctl &>/dev/null; then
  error "coredumpctl command not available"
  error "This script only works with systemd"
  exit 1
fi

if [[ -z "$1" ]]; then
  error "Please specify number of recent coredumps"
  error "$0 NUM"
  exit 2
fi

if ! [[ $1 =~ $numre ]]; then
  error "Argument must be numeric"
  error "e.g. $0 10"
  exit 3
fi

for pid in $(coredumpctl list --no-pager | tail -n $1 | awk '{print $5}');
do
  warn PID:$pid
  # Find first frame and remove leading whitespace
  coredumpctl info $pid | grep -i '#0' | sed 's/^\s\+//'
done
