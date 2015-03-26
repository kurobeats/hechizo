#!/usr/bin/env bash

echo Hechizo Uninstaller

# Check to ensure the script is run as root/sudo
if [ "$(id -u)" != "0" ]; 
then
echo "This script must be run as root. Later hater." 1>&2
exit 1
fi

# Removing build dependencies
apt-get remove libnl-dev libssl-dev

# Install dependencies
# apt-get remove apache2 dsniff isc-dhcp-server macchanger metasploit-framework python-dnspython python-pcapy python-scapy sslsplit stunnel4 tinyproxy procps iptables asleap

# Removing dirs
rm -rf /usr/share/hechizo
rm -rf /usr/lib/hechizo
rm -rf /etc/hechizo
rm -rf /var/lib/hechizo

echo "[+] Well, the script is done."

exit
