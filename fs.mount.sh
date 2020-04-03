#!/bin/bash
# script: fs.mount.sh
# author: Richard K @ www.rkkoranteng.com
# description: format and mount linux fs
# last modified: 11/28/2017

# example: ./fs.mount.sh xvda u01

if [ $# -ne 2 ]
then
 echo "Usage: $0 [device] [mount point]"
 exit
fi

devname=$1
mntname=$2

if [ ! -d /${mntname} ]
then
 mkdir /${mntname}
fi

mkfs.ext4 /dev/${devname}
echo "/dev/${devname} /${mntname} ext4 defaults,noatime 1 1" >> /etc/fstab
mount /${mntname}

df -h
