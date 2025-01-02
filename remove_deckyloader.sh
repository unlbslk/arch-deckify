#!/bin/bash

read -p \"Do you really want to uninstall Decky Loader? (y/n): \" confirm && if [[ \$confirm == \"y\" || \$confirm == \"Y\" ]]; then curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/uninstall.sh | sh; fi
