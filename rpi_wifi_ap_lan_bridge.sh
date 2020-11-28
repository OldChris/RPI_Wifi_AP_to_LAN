#!/bin/bash
# source is at : https://github.com/OldChris/RPI_Wifi_AP_to_LAN
# see README.md for instructions
#
# Provide a fail-over LAN by sharing neighbour Wifi AP with the Ethernet Port on the Raspberry Pi
#
#  Details Neighbours Wifi Access Point
#  (change as required)
#
nb_ssid="guest24"
nb_pass="guest24password"
keymgmt="WPA-PSK"
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
#  Local Network Interfaces
#  (you should be fine with thes values.)
# 
wlan="wlan0"
#
eth="eth0"
#
#  No need to edit below this line
#==========================================
#  Start of script, tell them who we are
os_name=`cat /etc/os-release |grep PRETTY_NAME | cut -d "=" -f 2`
computer=`hostname`
echo "This is host $computer, running $os_name"
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
\tkey_mgmt=$keymgmt\n\
}" > /tmp/wpa_supplicant.conf 
sudo cp /tmp/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
#
#  Restart Wifi interface with the new settings
echo "  Restart Wifi ..."
sudo wpa_cli -i $wlan reconfigure
#
#  Wait a bit to start, then check if UP
#
echo "  Wait 10 seconds for Wifi to complete startup..."
sleep 10
wlan_IP4=`ifconfig $wlan |grep "inet " |tr -s ' ' |cut -d ' ' -f 3`
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
eth_IP4=`ifconfig $eth |grep "inet " |tr -s ' ' |cut -d ' ' -f 3`
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