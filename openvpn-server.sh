#!/bin/sh
sh system-init.sh

# CERTIFICATES
apt -y install openvpn easy-rsa
mkdir /etc/openvpn/easy-rsa/
cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/

read -p "COUNTRY ? " COUNTRY
read -p "PROVINCE ? " PROVINCE
read -p "CITY ? " CITY
read -p "ORGANIZATION ? " ORG
read -p "EMAIL ? " EMAIL
read -p "ORGANIZATION UNIT ? " OU

sed -i "s/KEY_COUNTRY=\"US\"/KEY_COUNTRY=\"${COUNTRY}\"/g" /etc/openvpn/easy-rsa/vars
sed -i "s/KEY_PROVINCE=\"CA\"/KEY_PROVINCE=\"${PROVINCE}\"/g" /etc/openvpn/easy-rsa/vars
sed -i "s/KEY_CITY=\"SanFrancisco\"/KEY_CITY=\"${CITY}\"/g" /etc/openvpn/easy-rsa/vars
sed -i "s/KEY_ORG=\"Fort-Funston\"/KEY_ORG=\"${ORG}\"/g" /etc/openvpn/easy-rsa/vars
sed -i "s/KEY_EMAIL=\"me@myhost.mydomain\"/KEY_EMAIL=\"${EMAIL}\"/g" /etc/openvpn/easy-rsa/vars
sed -i "s/KEY_OU=\"MyOrganizationalUnit\"/KEY_OU=\"${OU}\"/g" /etc/openvpn/easy-rsa/vars

cd /etc/openvpn/easy-rsa/
. ./vars
./clean-all

./build-ca
cp keys/ca.crt /etc/openvpn/

./build-dh
cp keys/dh2048.pem /etc/openvpn/

./build-key-server server
cp keys/server.crt keys/server.key /etc/openvpn/

./build-key client
cp keys/client.crt keys/client.key /etc/openvpn/

cd /etc/openvpn
openvpn --genkey --secret /etc/openvpn/ta.key

# Activate routing
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# Bridge
apt -y install bridge-utils
#ip link show

STRINGTEST=$(cat /etc/network/interfaces|grep "iface br0 inet static")
if [ ${STRINGTEST} == "" ]; then
	read -p "INTERFACE TO BRIDGE ? " INT

	echo "

	auto ${INT}
	iface ${INT} inet manual
	  up ip link set \$IFACE up promisc on

	auto br0
	iface br0 inet static
	  address 10.8.0.4
	  netmask 255.255.255.0
	  bridge_ports ${INT}" >> /etc/network/interfaces

	ifdown ${INT} && ifup -a
fi

cat <<EOF > /etc/openvpn/up.sh
#!/bin/sh

BR=$1
ETHDEV=$2
TAPDEV=$3

/sbin/ip link set "$TAPDEV" up
/sbin/ip link set "$ETHDEV" promisc on
/sbin/brctl addif $BR $TAPDEV
EOF
chmod 755 /etc/openvpn/up.sh

# OPENVPN SERVER CONFIG
cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
gzip -d /etc/openvpn/server.conf.gz

sed -i 's/;dev tap/dev tap/g' /etc/openvpn/server.conf
sed -i 's/dev tun/dev tun/g' /etc/openvpn/server.conf
sed -i 's/server 10.8.0.0/;server 10.8.0.0/g' /etc/openvpn/server.conf
sed -i 's/;server-bridge 10.8.0.4 255.255.255.0 10.8.0.50 10.8.0.10/server-bridge 10.8.0.254 255.255.255.0 10.8.0.1 10.8.0.5/g' /etc/openvpn/server.conf
#sed -i 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/g' /etc/openvpn/server.conf
#sed -i 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS 8.8.8.8"/g' /etc/openvpn/server.conf
#sed -i 's/;push "dhcp-option DNS 208.67.220.220"/push "dhcp-option DNS 8.8.4.4"/g' /etc/openvpn/server.conf
sed -i 's/;client-to-client/client-to-client/g' /etc/openvpn/server.conf
sed -i 's/;duplicate-cn/duplicate-cn/g' /etc/openvpn/server.conf
sed -i 's/;compress lz4-v2/compress lz4-v2/g' /etc/openvpn/server.conf
sed -i 's/;push "compress lz4-v2"/push "compress lz4-v2"/g' /etc/openvpn/server.conf
sed -i 's/;comp-lzo/comp-lzo/g' /etc/openvpn/server.conf
sed -i 's/;user nobody/user nobody/g' /etc/openvpn/server.conf
sed -i 's/;group nogroup/group nogroup/g' /etc/openvpn/server.conf
sed -i 's/;log-append  openvpn.log/log-append  openvpn.log/g' /etc/openvpn/server.conf
sed -i 's/;mute 20/mute 20/g' /etc/openvpn/server.conf
echo "up '/etc/openvpn/up.sh br0 ${INT}'" >> /etc/openvpn/server.conf

systemctl start openvpn@server

# GENERATE CLIENT CONFIG FILE
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/

read -p "FQDN ? " FQDN

sed -i 's/;dev tap/dev tap/g' /etc/openvpn/client.conf
sed -i "s/;remote my-server-1 1194/remote ${FQDN} 1194/g" /etc/openvpn/client.conf
sed -i 's/;user nobody/user nobody/g' /etc/openvpn/client.conf
sed -i 's/;group nogroup/group nogroup/g' /etc/openvpn/client.conf
sed -i 's/;mute-replay-warnings/mute-replay-warnings/g' /etc/openvpn/client.conf
sed -i 's/;comp-lzo/comp-lzo/g' /etc/openvpn/client.conf
sed -i 's/;mute 20/mute 20/g' /etc/openvpn/client.conf