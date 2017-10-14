#!/bin/sh

# CERTIFICATES
apt -y install openvpn easy-rsa
mkdir /etc/openvpn/easy-rsa/
cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/

read -p 'COUNTRY ? ' COUNTRY
read -p 'PROVINCE ? ' PROVINCE
read -p 'CITY ? ' CITY
read -p 'ORGANIZATION ? ' ORG
read -p 'EMAIL ? ' EMAIL
read -p 'ORGANIZATION UNIT ? ' OU

sed -i "s/KEY_COUNTRY=\"US\"/KEY_COUNTRY=\"${COUNTRY}\"/g" /etc/openvpn/easy-rsa/vars
sed -i "s/KEY_PROVINCE=\"CA\"/KEY_PROVINCE=\"${PROVINCE}\"/g" /etc/openvpn/easy-rsa/vars
sed -i "s/KEY_CITY=\"SanFrancisco\"/KEY_CITY=\"${CITY}\"/g" /etc/openvpn/easy-rsa/vars
sed -i "s/KEY_ORG=\"Fort-Funston\"/KEY_ORG=\"${ORG}\"/g" /etc/openvpn/easy-rsa/vars
sed -i "s/KEY_EMAIL=\"me@myhost.mydomain\"/KEY_EMAIL=\"${EMAIL}\"/g" /etc/openvpn/easy-rsa/vars
sed -i "s/KEY_OU=\"MyOrganizationalUnit\"/KEY_OU=\"${OU}\"/g" /etc/openvpn/easy-rsa/vars

cd /etc/openvpn/easy-rsa/
. ./vars
./clean-all

mkdir /etc/openvpn/certs /etc/openvpn/ccd /etc/openvpn/log /etc/openvpn/clients /etc/openvpn/scripts

echo "
>>> Starting creation of CA"
./build-ca
cp keys/ca.crt /etc/openvpn/certs/.

./build-dh
cp keys/dh2048.pem /etc/openvpn/certs/.

echo "
>>> Starting creation of SERVER CERTIFICATE"
./build-key-server server
cp keys/server.crt keys/server.key /etc/openvpn/certs/.

cd /etc/openvpn
openvpn --genkey --secret /etc/openvpn/certs/ta.key

# Activate routing
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# Bridge
apt -y install bridge-utils
#ip link show

STRINGTEST=$(cat /etc/network/interfaces|grep "iface br0 inet static")
if [ "${STRINGTEST}" = "" ]; then
	read -p "INTERFACE TO BRIDGE ? " INT
	cat <<EOF >> /etc/network/interfaces
auto ${INT}
iface ${INT} inet manual

auto br0
iface br0 inet static
	address 10.9.1.254
	netmask 255.255.255.0
	broadcast 10.9.1.255
	bridge_ports ${INT}
	post-up /etc/init.d/openvpn start
	pre-down /etc/init.d/openvpn stop
	bridge_ports ${INT}
EOF
	ifdown ${INT} && ifup -a
fi

# OPENVPN SERVER CONFIG
wget -O /etc/openvpn/client.conf https://raw.githubusercontent.com/lspg/debian-scripts/master/vpn/openvpn/etc/openvpn/client.conf
wget -O /etc/openvpn/server.conf https://raw.githubusercontent.com/lspg/debian-scripts/master/vpn/openvpn/etc/openvpn/server-tap.conf
wget -O /etc/openvpn/scripts/up.sh https://raw.githubusercontent.com/lspg/debian-scripts/master/vpn/openvpn/etc/openvpn/scripts/up.sh
wget -O /etc/openvpn/scripts/down.sh https://raw.githubusercontent.com/lspg/debian-scripts/master/vpn/openvpn/etc/openvpn/scripts/down.sh
wget -O /etc/openvpn/scripts/client_tool.sh https://raw.githubusercontent.com/lspg/debian-scripts/master/vpn/openvpn/etc/openvpn/scripts/client_tool.sh
chmod 755 /etc/openvpn/scripts/*.sh

while true; do
	read -p "VPN NAME ? [MyVPN] " VPN_NAME
		case $VPN_NAME in
			"" ) VPN_NAME="MyVPN"; break;;
			*  ) break;;
	esac
done
echo "export VPN_NAME='${VPN_NAME}'" >> /etc/openvpn/scripts/vars

PUBLIC_IP="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
if [ ${#PUBLIC_IP} -gt 0 ]; then
	PUBLIC_IP="$(ifconfig | grep -A 1 'wan' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
fi

while true; do
	read -p "PUBLIC IP OR FQDN ? [${PUBLIC_IP}] " FQDN
		case $FQDN in
			"" ) FQDN="${PUBLIC_IP}"; break;;
			*  ) break;;
	esac
done

echo "export FQDN='${FQDN}'" >> /etc/openvpn/scripts/vars
sed -i "s/DOMAIN vpn.my.domain/DOMAIN vpn.my.domain ${FQDN}/g" /etc/openvpn/server.conf
sed -i "s/remote vpn.my.domain/remote ${FQDN}/g" /etc/openvpn/client.conf

if command -v systemctl 2>/dev/null; then
	systemctl enable openvpn-server@server
	systemctl restart openvpn-server@server
else
	sed -i 's/#AUTOSTART="home office"/AUTOSTART="server"/g' /etc/default/openvpn
	service openvpn restart
fi