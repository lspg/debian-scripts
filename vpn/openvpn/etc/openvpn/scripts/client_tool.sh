#!/bin/sh
. /etc/openvpn/easy-rsa/./vars

if [ -f /etc/openvpn/scripts/vars ]; then . /etc/openvpn/scripts/./vars; fi

if [ -z ${VPN_NAME+x} ]; then
    read -p 'VPN name : ' VPN_NAME
    echo 'export VPN_NAME="${VPN_NAME}"' >> /etc/openvpn/scripts/vars
fi

if [ -z ${FQDN+x} ]; then
    read -p 'FQDN : ' FQDN
    echo 'export FQDN="${FQDN}"' >> /etc/openvpn/scripts/vars
fi

read -p 'User name: ' USER
read -p 'User mail: ' MAIL
read -p 'Windows client ? (y/n) ' WIN

DIR="/etc/openvpn/clients/${VPN_NAME}"

mkdir -p ${DIR}

if [ ! -f "/etc/openvpn/easy-rsa/keys/${USER}.crt" ]; then
    echo -e ">>> User not found"
    echo -e ">>> Starting creation of CLIENT CERTIFICATE"
    /etc/openvpn/easy-rsa/./build-key ${USER}
else
    echo "User exists"
fi

ln -s /etc/openvpn/easy-rsa/keys/${USER}.crt ${DIR}/client.crt
ln -s /etc/openvpn/easy-rsa/keys/${USER}.key ${DIR}/client.key
ln -s /etc/openvpn/certs/ca.crt ${DIR}/ca.crt
ln -s /etc/openvpn/certs/ta.key ${DIR}/ta.key

cp /etc/openvpn/client.conf ${DIR}/${VPN_NAME}.ovpn

if [ $WIN = "y" ]; then
    OS="win"
    sed -i 's/user nobody/;user nobody/g' ${DIR}/${VPN_NAME}.ovpn
    sed -i 's/group nogroup/;group nogroup/g' ${DIR}/${VPN_NAME}.ovpn
else
    OS="nix"
fi

cp ${DIR}/${VPN_NAME}.ovpn ${DIR}/${VPN_NAME}-Gateway.ovpn
echo "redirect-gateway def1 bypass-dhcp" >> ${DIR}/${VPN_NAME}-Gateway.ovpn

cd /etc/openvpn/clients/
rm ${VPN_NAME}-VPN-${USER}-$OS.zip
zip ${VPN_NAME}-VPN-${USER}-$OS.zip ${VPN_NAME}/*
ZIPFILE="/etc/openvpn/clients/${VPN_NAME}-VPN-${USER}-$OS.zip"

# This needs heirloom-mailx
FROM="admin@${FQDN}"
TO=${MAIL}
SUBJECT="Profile client OpenVPN ${VPN_NAME} ($OS) : utilisateur '${USER}'"
BODY="Décompresser dans votre dossier utilisateur système, dans le sous dossier OpenVPN/config :

C:\Users
    └ ${USER}
        └ OpenVPN
            └ config
                └ ${VPN_NAME}
                    └ ${VPN_NAME}-Gateway.conf
                    └ client.crt
                    └ client.key
                    └ ${VPN_NAME}.conf
                    └ ta.key
                    └ ca.crt
"

declare -a ATTACHMENTS
ATTACHMENTS=( $ZIPFILE )

declare -a ATTARGS
for ATT in "${ATTACHMENTS[@]}"; do
    ATTARGS+=( "-a"  "$ATT" )
done

echo "Sending client config to ${MAIL}..."
mail -s "${SUBJECT}" -r "${FROM}" "${ATTARGS[@]}" "${TO}" <<< "${BODY}"

rm -Rf ${DIR}