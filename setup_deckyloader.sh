#!/bin/bash

curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh
sudo sed -i 's~TimeoutStopSec=.*$~TimeoutStopSec=2~g' /etc/systemd/system/plugin_loader.service
sudo systemctl daemon-reload
sudo systemctl restart plugin_loader.service
 echo '[Desktop Entry]
       Name=Uninstall Decky Loader
       Comment=Uninstalls Decky Loader from your system
       Exec=sh -c "read -p \"Do you really want to uninstall Decky Loader? (y/n): \" confirm && if [[ \$confirm == \"y\" || \$confirm == \"Y\" ]]; then curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/uninstall.sh | sh; fi"
       Icon=~/arch-deckify/steamdeck-gaming-return.png
       Terminal=true
       Type=Application
       StartupNotify=false' > "$XDG_DESKTOP_DIR/Uninstall_Decky_Loader.desktop"
