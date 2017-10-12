#!/bin/sh
openvpn --rmtun --dev tap0
/sbin/brctl delif br0 tap0
/sbin/ip link set tap down
/sbin/iptables -t nat -D POSTROUTING -j MASQUERADE