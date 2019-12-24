#!/bin/bash
# run this script with root

# these are the commands we actually need for the backup
command_list="echo tar hostname date split"

# verify that each command we use exists
for command in $command_list; do
 path=`which $command | grep "no $command in"`

 if [ ! -x `which $command` -a "$path" ]; then
  echo -e "\n\nERROR: $command not found! Check your commands and/or your \$PATH"
  exit -1
 fi
done

# options for the tar command
tarOptions="--create --absolute-names --preserve-permissions --totals --bzip2 --ignore-failed-read --verbose --file"

# where to put the stage4
stage4Location=/mnt/backups/stage4
if [ ! -d $stage4Location ]; then
	mkdir -p $stage4Location
fi

# name prefix
stage4prefix=$(hostname)-stage4-`date +\%d.\%m.\%Y`

# these files/directories are always excluded
default_exclude_list="
--exclude=/tmp/*
--exclude=/var/tmp/*
--exclude=/lost+found/*
--exclude=/dev/*
--exclude=/proc/*
--exclude=/mnt/*
--exclude=/sys/*
--exclude=/usr/portage/*
--exclude=/var/*
--exclude=/root/ubuntu-xenial/*
--exclude=/root/linux-*
--exclude=/root/gdb-*
--exclude=/root/debs/*
--exclude=/root/qemu*
--exclude=/root/fabvm/*
--exclude=/boot/*
--exclude=/opt/*
--exclude=/usr/src/*
--exclude=/usr/lib/debug/*
--exclude=$stage4Location"

# depending on your choice these files or directories will additionally be excluded
custom_exclude_list="
--exclude=/usr/src/*
--exclude=/home/*"

# check the folder/files stored in $default_exclude_list exist
for exclude in $default_exclude_list; do
   if [ ! -e "`echo "$exclude" | cut -d'=' -f2 | cut -d'*' -f1`"  ]; then
      echo -e "\n\nERROR: `echo "$exclude" | cut -d'=' -f2` not found! Check your \$default_exclude_list"
   fi
done

# check the folder/files stored in $custom_exclude_list exist
for exclude in $custom_exclude_list; do
   if [ ! -e "`echo "$exclude" | cut -d'=' -f2 | cut -d'*' -f1`"  ]; then
      echo -e "\n\nERROR: `echo "$exclude" | cut -d'=' -f2` not found! Check your \$custom_exclude_list"
   fi
done

# how do you want to backup?
echo -e "\nWhat do you want to do? (Use CONTROL-C to abort)\n
(1) Minimal backup
(2) Interactive backup"

while [ "$option" != '1' -a "$option" != '2'  ]; do
   echo -en "\nPlease enter your option: "
   read option
done

case $option in
1)
   stage4Name=$stage4Location/$stage4prefix-minimal
   final_command="tar $default_exclude_list $custom_exclude_list $tarOptions $stage4Name.tar.bz2 / /var/log/emerge.log"
   ;;
2)
   for folder in $custom_exclude_list; do
      echo -en "Do you want to backup" `echo "$folder" | cut -d'=' -f2`"? (y/n) "
      read answer
      while [ "$answer" != 'y' -a "$answer" != 'n' ]; do
         echo "please enter y or n"
         read answer
      done
      if [ "$answer" == 'n' ]; then
         default_exclude_list="$default_exclude_list $folder"
      fi
   done

   stage4Name=$stage4Location/$stage4prefix-custom
   final_command="tar $default_exclude_list $tarOptions $stage4Name.tar.bz2 /  /var/log/emerge.log"
   ;;
esac

# show what will be done
echo -e "\n* creating the stage4 at $stage4Location with the following options:\n\n"$final_command

# everything is set, are you sure to continue?
echo -ne "\nDo you want to continue? (y/n) "
read answer
while [ "$answer" != 'y' ] && [ "$answer" != 'n' ]; do
         echo "please enter y or n"
         read answer
done

if [ "$answer" == 'y' ]; then
   # mount boot
   echo -e "\n* mount boot"
   mount /boot >/dev/null 2>&1

   # if necessary, create the stage4Location
   if [ ! -d "$stage4Location" ] ; then
      echo "* creating directory $stage4Location"
      mkdir -p $stage4Location
   fi

   # check whether the file already exists
   if [ -a "$stage4Name.tar.bz2" ]; then
      echo -en "\nDo you want to overwrite $stage4Name.tar.bz2? (y/n) "
      read answer
      while [ "$answer" != 'y' ] && [ "$answer" != 'n' ]; do
         echo "please enter y or n"
         read answer
      done
      if [ "$answer" == 'n' ]; then
         echo -e "\n* There's nothing to do ... Exiting"
         exit 0;
      fi
   fi

   # do the backup
   time $final_command

   # copy the current world file to the stage4 location
   echo -e "\n* creating stage4 overview $stage4Name.txt"
   cp /var/lib/portage/world $stage4Name.txt >/dev/null 2>&1

   # we finished, clean up
   echo "* stage4 is done"
   echo "* umounting boot"
   umount /boot
else
   echo -e "\n* There's nothing to do ... Exiting"
fi

#Uncomment the following command if you want to split the archive in cd size chunks:
#split --suffix-length=1 --bytes=670m $stage4Name.tar.bz2 "$stage4Name"_ && echo "* splitting is done"
