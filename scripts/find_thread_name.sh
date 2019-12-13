#!/bin/bash

qemu_pid=`pidof qemu-system-x86_64`
qemu_path="/proc/$qemu_pid"

# enter the task
cd $qemu_path/task

# printout tid and name
for tid in `ls`
do
	echo -e "pid($tid) \c" $tid && cat $tid/comm
done
