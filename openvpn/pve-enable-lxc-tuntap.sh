#!/bin/sh
read -p "CONTAINER ID ? " CTID

STRING="lxc.cgroup.devices.allow: c 10:200 rwm"
STRINGTEST=$(cat /etc/pve/lxc/${CTID}.conf|grep "${STRING}")
if [ "$STRINGTEST" == "" ]; then
	echo ${STRING} >> /etc/pve/lxc/$CTID.conf
	echo "Line added to /etc/pve/lxc/$CTID.conf : ${STRING}"
else
	echo "Line already present in /etc/pve/lxc/$CTID.conf : ${STRING}"
fi

STRING='lxc.hook.autodev: sh -c "modprobe tun; cd ${LXC_ROOTFS_MOUNT}/dev; mkdir net; mknod net/tun c 10 200; chmod 0666 net/tun"'
STRINGTEST=$(cat /etc/pve/lxc/${CTID}.conf|grep "${STRING}")
if [ "$STRINGTEST" == "" ]; then
	echo ${STRING} >> /etc/pve/lxc/$CTID.conf
	echo "Line added to /etc/pve/lxc/$CTID.conf : ${STRING}"
else
	echo "Line already present in /etc/pve/lxc/$CTID.conf : ${STRING}"
fi