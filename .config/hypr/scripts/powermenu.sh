#!/bin/bash

# Power options
options=" Lock\n󰍃 Logout\n Suspend\n Reboot\n Shutdown"

chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power Menu")

case "$chosen" in
    " Lock") 
        # If you use swaylock
        swaylock -f -c 000000 
        ;;
    "󰍃 Logout") 
        hyprctl dispatch exit
        ;;
    " Suspend") 
        systemctl suspend
        ;;
    " Reboot") 
        systemctl reboot
        ;;
    " Shutdown") 
        systemctl poweroff
        ;;
esac
