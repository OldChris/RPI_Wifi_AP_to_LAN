# RPI_Wifi_AP_to_LAN

## What is RPI_Wifi_AP_to_LAN ?
In case your ISP can not provide Internet connection, this allows all your computers to connect to Internet via a Wifi AP of your neighbour. (provided that has Internet connection)

The script is based on:
*  [Article by Instructables.com](https://www.instructables.com/id/Share-WiFi-With-Ethernet-Port-on-a-Raspberry-Pi/)
*  [Github repo of Arpit Agarwal (arpitjindal97) ](https://github.com/arpitjindal97/raspbian-recipes)


## How does it work?
RPI_Wifi_AP_to_LAN makes a connection with the Wifi AP of the neighbour (we assume it has Internet connection)
This should be a so-called Guest AP with no access to neighbour's LAN, only connection to Internet

Prepare yourself:
* Discus fail-over scenario with neighbour and agree
* Maybe neighbour has to configure a guest AP 
* Enter Wifi AP of neighbour in the script
* Shutdown and store Raspberry Pi.
* Make sure that all computers are on a single switch that has a connection to your ISP's Modem, do connect computers to other ISP's Modem ports

Fail over steps:
* Contact neighbour and agree that fail-over is allowed by neighbour
* Maybe neighbour has to activate Wifi guest AP for you
* power up Raspberry Pi
* Switch off your ISP's Modem
* Take the connection of your switch to your ISP Modem from the ISP Modem and put it in the RJ45 connector of the Raspberry Pi
* Restart your computers 

Your fail-over LAN has a DHCP service so your computers should all connect after a reboot.

## How to build?
RPI_Wifi_AP_to_LAN consist of:
* A Rapberry PI
* Buster OS
* put the script in /home/pi 
* edit values of Wifi AP and local LAN config as needed
* add a crontab entry for root 

## Who will use it?
Anyone with a friendly neighbour that gives access to his/hers Wifi guest AP  
This can your home neighbour or (small) office neighbour
Talk to them and make arrangments before your ISP connection fails.

## Goal , next steps

Any suggestions are welcome.