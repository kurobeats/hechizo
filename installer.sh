#!/usr/bin/env bash

echo Hechizo Installer
echo [+] This installer assumes you are runnning Kali Linux. If you are not, hit Ctl-C now, but if you are, know what you\'re doing or don\'t care, hit Enter to continue
read

# Check to ensure the script is run as root/sudo
if [ "$(id -u)" != "0" ]; 
then
echo "This script must be run as root. Later hater." 1>&2
exit 1
fi

# Install build dependencies
apt-get install libnl-dev libssl-dev
make

# Install dependencies
apt-get install apache2 dsniff isc-dhcp-server macchanger metasploit-framework python-dnspython python-pcapy python-scapy sslsplit stunnel4 tinyproxy procps iptables asleap
make install

echo "[+] Well, the script is done."

exit
