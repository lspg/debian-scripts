# On Proxmox host

* Create an LXC container with 2 NICs:
** eth0 on vmbr0, Public IP
** eth1 on vmbr3, VPN LAN

* On Proxmox host, enable tun/tap interface for the new LXC Container :
```
wget -O /etc/pve/enable-lxc-tuntap.sh https://raw.githubusercontent.com/lspg/debian-scripts/master/vpn/openvpn/pve-enable-lxc-tuntap.sh
sh /etc/pve/enable-lxc-tuntap.sh
pct restart $CTID
pct enter $CTID
```

* In the VM
```
apt update; apt -y install ca-certificates
wget -O - https://raw.githubusercontent.com/lspg/debian-scripts/master/vpn/openvpn/opnvpn-server-tap-install.sh | sh
```