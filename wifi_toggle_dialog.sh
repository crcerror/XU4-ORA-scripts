#!/bin/sh
# activate/deactivate wifi setting (dialog toggle)
# by cyperghost

MYIP=$(ip a s|sed -ne '/127.0.0.1/!{s/^[ \t]*inet[ \t]*\([0-9.]\+\)\/.*$/\1/p}')
WLANSTAT=$(nmcli radio wifi | grep -c "disabled")

[ ${#MYIP} -eq 0 ] && MYIP="NO CONNECTION!"
ip_text="  Your IP adress is:\n\n$MYIP\n\n"

if [ $WLANSTAT -ge 1 ]; then
    ip_text="${ip_text}\n  Your WiFi adapter seems to be blocked or is not available.\n\n\
             Select ENABLE WIFI to activate or unblock WiFi device\n             Select CANCEL to abort any action!"
    action="sudo nmcli radio wifi on"
    button="Enable WiFi"
else
    ip_text="${ip_text}\n  Your WiFi adapter seems to be activated.\n\n\
             Select BLOCK WIFI to disable or block WiFi device\n             Select CANCEL to abort any action!"
    action="sudo nmcli radio wifi off"
    button="Block WiFi"
fi

whiptail --title "Change WiFi status" --defaultno \
         --backtitle "RFKILL dialog - enable/disable WiFi adapters" \
         --yes-button "$button" --no-button "Cancel" \
         --yesno "$ip_text" 0 0

[ $? -eq 0 ] && $action
