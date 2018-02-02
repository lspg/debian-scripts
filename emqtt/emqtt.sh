#!/bin/bash

# Usage :
# Install a fresh Debian Jessie, then execute following shell command as root user
# wget --no-check-certificate -O -  | bash

############
# Settings #
############

export LOCALE="fr_FR.UTF-8"
export TIMEZONE="Europe/Paris"

#############
# Functions #
#############

# Colors
c1="\e[39m" # Normal
c2="\e[91m" # Red
c3="\e[92m" # Light Green
c4="\e[36m" # Cyan
c5="\e[31m" # Light Red
c6="\e[93m" # Yellow
c7="\e[32m" # Green
c8="\e[97m" # White

function tst {
	echo -e "${c7}   => $*${c4}"
	if ! $*; then
		echo -e "${c5}Exiting script due to error from: $*${c1}"
		exit 1
	fi
	echo -en "${c1}"
}

function out {
	if [ ! $CNT ]; then CNT=0; fi
	CNT=$((CNT+1))
	printf -v NUM "%02d" $CNT
	echo -e "${c3}${NUM} => $*${c1}"
}

function conf {
	echo "$*" | debconf-set-selections
}

# FIND ABSOLUTE SCRIPT PATH
SOURCE="${BASH_SOURCE[0]}"

while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	ROOT="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
ROOT="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

echo -e "${c3}*****************************************"	
echo -e      "*** Axelor Business Suite 4.1 install ***"
echo -e      "*****************************************${c1}"

#############
# Bootstrap #
#############"
out "Repositories"
cat <<EOF > /etc/apt/sources.list
deb http://httpredir.debian.org/debian/ jessie main contrib
deb http://httpredir.debian.org/debian/ jessie-updates main contrib
deb http://security.debian.org jessie/updates main contrib
EOF
tst apt update -qq
tst apt install -yq debconf-utils

out "Bash customization"
sed -f- -i ~/.bashrc <<- EOF
s|^# export LS_OPTIONS=.*|export LS_OPTIONS=\'--color=auto\'|;
s|^# eval \"\`dircolors\`\"|eval \"\`dircolors\`\"|;
s|^# alias l=.*|alias l=\'ls $LS_OPTIONS -lA\'|;
EOF
tst . /root/.bashrc

out "SSH Config"
sed -f- -i /etc/ssh/sshd_config <<- EOF
s|^#AuthorizedKeysFile.*|AuthorizedKeysFile     %h/.ssh/authorized_keys|;
s|^PermitRootLogin.*|PermitRootLogin yes|;
EOF
tst service ssh restart

out "Locales"
sed -i "s/# en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
sed -i "s/# ${LOCALE}/${LOCALE}/g" /etc/locale.gen
tst locale-gen
tst dpkg-reconfigure -f noninteractive locales
echo "Language=${LOCALE}" > /etc/environment
tst . /etc/environment

out "Timezone"
echo ${TIMEZONE} > /etc/timezone
tst dpkg-reconfigure -f noninteractive tzdata

out "System upgrade"
tst apt update -qq
tst apt upgrade -yq
tst apt-get -yq autoremove --purge

#########
# EMQTT #
#########



###########
# Cleanup #
###########
out "Cleanup"
tst apt-get autoremove -qy --purge
tst apt-get clean -qy
tst rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

########################
# Check axelor startup #
########################
out "Watching Axelor startup... (CTL+C to quit)"
tst tail -f /var/log/tomcat${TOMCAT_VERSION}/catalina.out