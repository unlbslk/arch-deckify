#!/bin/bash
if [ ! -f /usr/bin/steamos-session-select ]; then
  echo -e "\e[31m[ERROR] \e[0m/usr/bin/steamos-session-select not found on this system. The script may have been deleted, not installed, or interrupted during installation for some reason. If the installation is incomplete, please install again. This script will create this file again now."
fi
available_desktops=$(ls /usr/share/wayland-sessions/*.desktop 2>/dev/null | sed 's|/usr/share/wayland-sessions/||' | sed 's/\.desktop$//' | grep -v 'gamescope')

if [ -z "$available_desktops" ]; then
    echo -e "\e[31m[ERROR] \e[0mNo wayland session for desktop mode was found on your system."
    exit 1
fi
while true; do
    echo -e "\n\e[95mCurrent Wayland sessions in the system:\n\e[0m"
    echo "$available_desktops"
    echo -e "\n\e[95mWhich one should be used when switching from Steam to desktop mode?\n\e[0m"
    read -p "Enter a session name: " user_choice

    if echo "$available_desktops" | grep -q -w "^$user_choice"; then
        selected_de="$user_choice"
        echo '#!/usr/bin/bash

CONFIG_FILE="/etc/sddm.conf"
# If no arguments are provided, list valid arguments
if [ $# -eq 0 ]; then
    echo "Valid arguments: plasma, gamescope"
    exit 0
fi

# If the argument is "plasma"
# IMPORTANT: If you want to use a desktop environment other than KDE Plasma, do not change the IF command. 
# Steam always runs this file as "steamos-session-select plasma" to switch to the desktop. 
# Instead, change the code below that edits the config file.

if [ "$1" == "plasma" ] || [ "$1" == "desktop" ]; then
    
    echo "Switching session to Desktop."
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "SDDM config file could not be found at ${CONFIG_FILE}."
        exit 1
    fi
    NEW_SESSION='$selected_de' # For other desktops, change here.
    sudo sed -i "s/^Session=.*/Session=${NEW_SESSION}/" "$CONFIG_FILE"
    steam -shutdown

# If the argument is "gamescope"
elif [ "$1" == "gamescope" ]; then
    
    echo "Switching session to Gamescope."
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "SDDM config file could not be found at ${CONFIG_FILE}."
        exit 1
    fi
    NEW_SESSION="gamescope-session-steam"
    sudo sed -i "s/^Session=.*/Session=${NEW_SESSION}/" "$CONFIG_FILE"
    dbus-send --session --type=method_call --print-reply --dest=org.kde.Shutdown /Shutdown org.kde.Shutdown.logout || gnome-session-quit --logout --no-prompt || cinnamon-session-quit --logout --no-prompt || loginctl terminate-session $XDG_SESSION_ID
else
    echo "Valid arguments are: plasma, gamescope."
    exit 1
fi' | sudo tee /usr/bin/steamos-session-select > /dev/null
        sudo chmod +x /usr/bin/steamos-session-select
        echo -e "\e[93m'$user_choice' is selected.\e[0m\n"
        
        break
    else
        echo -e "\n\e[31m[ERROR] \e[93m No desktop named '$user_choice' found.\e[0m\n\n"
    fi
done
