#!/bin/bash
# source is at : https://github.com/OldChris/RPI_Wifi_AP_to_LAN
# see README.md for instructions
#
# Provide a fail-over LAN by sharing neighbour Wifi AP with the Ethernet Port on the Raspberry Pi
#  Functions
#
configFile="config.txt"

getConfig()
{
    local result=$1  # variable name for result
    local param=$2   # entry in config file
    local default=$3 # default value in case no entry in config file
#
    file="/media/*/*/$configFile"
    if [ -e $file ]
    then
        value=`cat $file| tr -d ' '| grep "^$param=" | cut -d '=' -f2`
        if [ -z $value ] 
        then
	    echo "    No user defined value for $param, using default ($default) "
	else
            eval $result="'$value'"
            echo "    Using user defined value for $param ($value) "
	fi
    fi
}
#
#  Local Network Interfaces
#
eth="eth0"
wlan="wlan0"
#
#  Details Neighbours Wifi Access Point
#  (change as required)
#
nb_ssid="guest_ap"
nb_pass="guest_ap_password"
nb_keymgmt="WPA-PSK"
country="NL"
#
#  Details of the new local network with DHCP 
#  (change as required)
#
ip_address="192.168.2.1"
netmask="255.255.255.0"
dhcp_range_start="192.168.2.2"
dhcp_range_end="192.168.2.100"
dhcp_time="12h"
#
#  No need to edit below this line
#==========================================
#
#
#  Start of script, tell them who we are
os_name=`cat /etc/os-release |grep PRETTY_NAME | cut -d "=" -f 2`
computer=`hostname`
echo "This is host $computer, running $os_name"
up_seconds=`cat /proc/uptime |cut -d ' ' -f 1|cut -d '.' -f 1`
time_to_bootup=60
if [ $up_seconds -lt $time_to_bootup ]
then
    wait_seconds=$(($time_to_bootup - $up_seconds))
    echo " just booted, waiting $wait_seconds seconds for Wifi interface and mounting of USB stick"
    sleep $wait_seconds
fi

#  See if user has entries in config.txt
   file="/media/*/*/$configFile"
    if [ -e $file ]
    then
        echo "Config file found ($file)"
        getConfig nb_ssid "nb_ssid" $nb_ssid
        getConfig nb_pass "nb_pass" $nb_pass
        getConfig nb_keymgmt "nb_keymgmt" $nb_keymgmt
        getConfig country "country" $country
        getConfig wlam "wlan" $wlan
        getConfig eth "eth" $eth
        getConfig ip_address "ip_address" $ip_address
        getConfig netmask "netmask" $netmask
        getConfig dhcp_range_start "dhcp_range_start" $dhcp_range_start
        getConfig dhcp_range_end "dhcp_range_end" $dhcp_range_end
        getConfig dhcp_time "dhcp_time" $dhcp_time
    else
        echo "No Config file found on USB stick (filename $configFile)"
        echo -e " example:\n \
wlan=wlan0\t# use if your Wifi interface differs from $wlan\n \
eth=eth0\t# use if your Ethernet interface differs from $eth\n \
nb_ssid = guest_ap\t # use if the SSID differs from $nb_ssid\n \
nb_pass=guest_ap_passwd\t # use if the Wifi paasword differs from $nb_pass\n \
country=NL\t# use if your WIFI country code differs from $country\n \
nb_keymgmt=WPA-PSK\t # only use if Wifi key management differs from $nb_keymgmt\n \
ip_address=192.168.2.1\t # use if you want a different IP address then $ip_address\n \
netmask=255.255.255.0\t # use if you want a netmaks other then $netmask\n \
dhcp_range_start=192.168.2.2\t # use if you want a DHCP range start other then $dhcp_range_start\n \
dhcp_range_end=192.168.2.100\t # use if you want a DHCP range end other then $dhcp_range_end\n \
dhcp_time=12h\t # use if you want a DHCP release time other then $dhcp_time\n"
    fi

echo "  Create new Wifi config..."
#
#  Create /etc/wpa_supplicant/wpa_supplicant.conf
#
sudo echo -e "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\n\
update_config=1
country=$country\n\
\n\
network={\n\
\tssid=\"$nb_ssid\"\n\
\tpsk=\"$nb_pass\"\n\
\tkey_mgmt=$nb_keymgmt\n\
}" > /tmp/wpa_supplicant.conf 
sudo cp /tmp/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
#
#  Restart Wifi interface with the new settings
echo "  Restart Wifi ..."
sudo wpa_cli -i $wlan reconfigure
#
#  Wait a bit to start, then check if UP
#
echo "  Wait 15 seconds for Wifi to complete startup..."
sleep 15
wlan_IP4=`/sbin/ifconfig $wlan |grep "inet " |tr -s ' ' |cut -d ' ' -f 3`
echo "  Wifi IP address is $wlan_IP4"
#
#  Setup forwarding
#
sudo systemctl start network-online.target &> /dev/null

sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t nat -A POSTROUTING -o $wlan -j MASQUERADE
sudo iptables -A FORWARD -i $wlan -o $eth -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $eth -o $wlan -j ACCEPT

sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

sudo ifconfig $eth $ip_address netmask $netmask

# Remove default route created by dhcpcd
sudo ip route del 0/0 dev $eth &> /dev/null
echo "  Sleep 10 seconds for Ethernet to start..."
sleep 10
eth_IP4=`/sbin/ifconfig $eth |grep "inet " |tr -s ' ' |cut -d ' ' -f 3`
echo "  Ethernet IP address is $eth_IP4"
#
#  Configure DHCP
#
sudo systemctl stop dnsmasq

sudo rm -rf /etc/dnsmasq.d/* &> /dev/null

echo -e "interface=$eth\n\
bind-interfaces\n\
server=8.8.8.8\n\
domain-needed\n\
bogus-priv\n\
dhcp-range=$dhcp_range_start,$dhcp_range_end,$dhcp_time" > /tmp/custom-dnsmasq.conf
#
#  Start DHCP
#
sudo cp /tmp/custom-dnsmasq.conf /etc/dnsmasq.d/custom-dnsmasq.conf
sudo systemctl start dnsmasq
echo "End of script"
#
#  End of script
#