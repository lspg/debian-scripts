#!/bin/sh

# Locales and Timezone
sed -i 's/# en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
sed -i 's/# fr_FR.UTF-8/fr_FR.UTF-8/g' /etc/locale.gen
locale-gen && dpkg-reconfigure locales tzdata

# System upgrade
apt update; apt -y upgrade

# Screenfetch
apt -y install screenfetch
STRING="screenfetch"
STRINGTEST=$(cat ~/.bashrc|grep "${STRING}")
if [ ${#STRINGTEST} -eq 0 ]; then
	echo ${STRING} >> ~/.bashrc
fi

# BashRC
sed -i 's/# export LS_OPTIONS/export LS_OPTIONS/g' ~/.bashrc
sed -i 's/# alias l=/alias l=/g' ~/.bashrc

# Aliases
cat <<EOF > ~/.aliases
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
EOF
STRING=". ~/.aliases"
STRINGTEST=$(cat ~/.bashrc|grep "${STRING}")
if [ ${#STRINGTEST} -eq 0 ]; then
	echo ${STRING} >> ~/.bashrc
fi

. ~/.bashrc

# Clock sync
apt -y install ntp ntpdate