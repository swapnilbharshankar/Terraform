#!/bin/bash
#
# summarize daily performance data

cd /var/log/sa

# ------------
# memory usage
# ------------
echo
echo "Memory & Swap"
echo "============="
echo -n "           "
sar -r -f $file | head -3 | tail -1 | awk '{print substr($0,12,100)}'
for file in `ls -tr sa* | grep -v sar`
do
    dt=`sar -r -f $file | head -1 | awk '{print $NF}'`
    echo -n $dt
    sar -r -f $file | tail -1 | sed "s/Average:  //"
done

# ------------
# load
# ------------
echo
echo "System Load"
echo "============="
echo -n "           "
sar -q -f $file | head -3 | tail -1 | awk '{print substr($0,12,100)}'
for file in `ls -rt sa* | grep -v sar`
do
    dt=`sar -q -f $file | head -1 | awk '{print $NF}'`
    echo -n $dt
    sar -q -f $file | tail -1 | sed "s/Average:  //"
done

# ------------
# CPU Usage
# ------------
echo
echo "CPU Usage"
echo "============="
echo -n "           "
sar -u -f $file | head -3 | tail -1 | awk '{print substr($0,12,100)}'
for file in `ls -tr sa* | grep -v sar`
do
    dt=`sar -u -f $file | head -1 | awk '{print $NF}'`
    echo -n $dt
    sar -u -f $file | tail -1 | sed "s/Average:  //"
done
