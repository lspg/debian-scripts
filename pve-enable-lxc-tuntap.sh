#!/bin/bash
read -p "CONTAINER ID ? " CTID
echo "Creating file : /var/lib/lxc/$CTID/autodev-tuntap"
cat <<EOF > /var/lib/lxc/$CTID/autodev-tuntap
#!/bin/bash
modprobe tun
cd ${LXC_ROOTFS_MOUNT}/dev
mkdir net
mknod net/tun c 10 200
chmod 0666 net/tun
EOF
chmod +x /var/lib/lxc/$CTID/autodev-tuntap

STRING="lxc.hook.autodev: sh /var/lib/lxc/${CTID}/autodev"
STRINGTEST=$(cat /etc/pve/lxc/${CTID}.conf|grep "${STRING}")
if [ "$STRINGTEST" == "" ]; then
	echo "Line added to /etc/pve/lxc/$CTID.conf : ${STRING}"
	echo ${STRING} >> /etc/pve/lxc/$CTID.conf
else
	echo "Line already present in /etc/pve/lxc/$CTID.conf : ${STRING}"
fi

STRING="lxc.cgroup.devices.allow: c 10:200 rwm"
STRINGTEST=$(cat /etc/pve/lxc/${CTID}.conf|grep "${STRING}")
if [ "$STRINGTEST" == "" ]; then
	echo "Line added to /etc/pve/lxc/$CTID.conf : ${STRING}"
	echo ${STRING} >> /etc/pve/lxc/$CTID.conf
else
	echo "Line already present in /etc/pve/lxc/$CTID.conf : ${STRING}"
fi