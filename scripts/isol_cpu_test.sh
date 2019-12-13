#!/bin/bash
# run script ./test_cpu.sh > result.txt 2>&1

# check cmdline
cat /proc/cmdline

echo -e

# move rcu threads to the non-latency-sensitive core(none isolation core)
nls_core=0
for i in `pgrep rcu[^c]` ; do taskset -pc $nls_core $i ; done

# Optionally
# set CPU affinity for the kernel's write-back bdi-flush threads
# to the housekeeping core
echo 1 > /sys/bus/workqueue/devices/writeback/cpumask

# numbers of cpu
cpus=`grep process /proc/cpuinfo | wc -l`
cpus=$(( $cpus - 1 ))

for cpu_id in `seq 0 $cpus`
do
        perf stat -C $cpu_id -e irq_vectors:local_timer_entry taskset -c $cpu_id stress -t 1 -c 1
        sleep 2
done
