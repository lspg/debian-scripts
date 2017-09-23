#!/bin/sh
read -p "CONTAINER ID ? " CTID
cat <<EOF > /var/lib/lxc/$CTID/autodev
#!/bin/bash
cd ${LXC_ROOTFS_MOUNT}/dev
mkdir net
mknod net/tun c 10 200
chmod 0666 net/tun
EOF

echo "lxc.cgroup.devices.allow: c 10:200 rwm" >> /etc/pve/lxc/$CTID.conf
echo "lxc.hook.autodev: /var/lib/lxc/$CTID/autodev" >> /etc/pve/lxc/$CTID.conf