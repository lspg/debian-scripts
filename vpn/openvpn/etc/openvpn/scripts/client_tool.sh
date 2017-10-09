#!/bin/bash

cd /etc/openvpn/easy-rsa/
. ./vars

# USER CREATION
read -p 'User name: ' USER
read -p 'User mail: ' MAIL
read -p 'Windows client ? (y/n) ' WIN

DIR="/etc/openvpn/clients/CCC"

mkdir -p $DIR

if [ ! -f "/etc/openvpn/easy-rsa/keys/$USER.crt" ]; then
  echo "User do not exists"
  /etc/openvpn/easy-rsa/./build-key $USER
else
  echo "User exists"
fi

ln -s /etc/openvpn/easy-rsa/keys/$USER.crt $DIR/client.crt
ln -s /etc/openvpn/easy-rsa/keys/$USER.key $DIR/client.key
ln -s /etc/openvpn/certs/ca.crt $DIR/ca.crt
ln -s /etc/openvpn/certs/ta.key $DIR/ta.key

cp /etc/openvpn/client.conf $DIR/CCC.ovpn

if [ $WIN = "y" ]; then
  OS="win"
  sed -i 's/user nobody/;user nobody/g' $DIR/CCC.ovpn
  sed -i 's/group nogroup/;group nogroup/g' $DIR/CCC.ovpn
else
  OS="nix"
fi

cp $DIR/CCC.ovpn $DIR/CCC-Gateway.ovpn
echo "redirect-gateway def1 bypass-dhcp" >> $DIR/CCC-Gateway.ovpn

cd /etc/openvpn/clients/
rm CCC-VPN-$USER-$OS.zip
zip CCC-VPN-$USER-$OS.zip CCC/*
ZIPFILE="/etc/openvpn/clients/CCC-VPN-$USER-$OS.zip"

# This needs heirloom-mailx
from="vpn@kctus.pro"
to=$MAIL
subject="Profile client OpenVPN CCC ($OS) : utilisateur '$USER'"
body="Décompresser dans votre dossier utilisateur système, dans le sous dossier OpenVPN/config :

C:\Users
    └ $USER
        └ OpenVPN
            └ config
                └ CCC
                    └ CCC-Gateway.conf
                    └ client.crt
                    └ client.key
                    └ CCC.conf
                    └ ta.key
                    └ ca.crt
"

declare -a attachments
attachments=( $ZIPFILE )

declare -a attargs
for att in "${attachments[@]}"; do
  attargs+=( "-a"  "$att" )
done

echo "Sending client config to $MAIL..."
mail -s "$subject" -r "$from" "${attargs[@]}" "$to" <<< "$body"

rm -Rf $DIR