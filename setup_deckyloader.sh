#!/bin/bash

sudo pacman -S jq --noconfirm
curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh
sudo sed -i 's~TimeoutStopSec=.*$~TimeoutStopSec=2~g' /etc/systemd/system/plugin_loader.service
sudo systemctl daemon-reload
sudo systemctl restart plugin_loader.service
echo "Installed Decky Loader."