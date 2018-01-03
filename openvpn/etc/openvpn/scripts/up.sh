#!/bin/sh
openvpn --mktun --dev tap0
/sbin/ip link set lan up promisc on
/sbin/ip link set tap0 up promisc on
/sbin/brctl addif br0 tap0
/sbin/iptables -t nat -A POSTROUTING -j MASQUERADE