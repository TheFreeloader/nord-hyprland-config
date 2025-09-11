#!/bin/bash

# Power options
options=" Lock\n󰍃 Logout\n Suspend\n Reboot\n Shutdown"

chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power Menu")

case "$chosen" in
    " Lock") 
        # If you use swaylock
        ~/.config/hypr/scripts/lock.sh
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
