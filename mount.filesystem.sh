#!/bin/bash
# script: mount_fs.sh
# author: Richard K @ www.rkkoranteng.com
# desc: format and mount linux fs
# last modified: 11/28/2017

# example: ./mount.filesystem.sh xvda u01

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
