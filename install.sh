#!/bin/bash

if [ "$EUID" -eq 0 ]; then
    echo -e "\e[91mERROR:\e[0m Run this script WITHOUT root/sudo privileges."
    exit 1
fi

echo -e "\n\n\e[1;33mWelcome to Arch Deckify Script\e[0m"
echo -e "\e[91mWarning: This script mostly does not work on NVIDIA cards.\e[0m"
echo -e "\e[37mThis script has been made to work only on Plasma Login Manager.\e[0m"
echo -e "\e[37mYou must make additional changes for other display managers.\n\n\e[0m"
dm=$(basename "$(readlink /etc/systemd/system/display-manager.service)")

if [[ "$dm" != "plasmalogin.service" ]]; then
    echo -e "\e[31m[ERROR] \e[0mPlasma Login Manager is not found. (see: https://unlbslk.github.io/arch-deckify/issues/#what-is-the-plasma-login-manager-and-how-can-i-install-it)"
    exit 1
fi

sudo whoami
echo

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
    echo -e "\e[93m'$user_choice' is selected.\e[0m\n"
    selected_de="$user_choice"
    break
  else
    echo -e "\n\e[31m[ERROR] \e[93m No desktop named '$user_choice' found.\e[0m\n\n"
  fi
done

echo -e "\n\e[36m [1/18]\e[0m Checking if yay or paru is installed...\n"

if command -v yay &> /dev/null; then
    echo "Yay is already installed. (SKIPPED)"
elif command -v paru &> /dev/null; then
    echo "Paru is already installed. (SKIPPED)"
else
    echo "Neither yay nor paru found. Installing yay..."
    sudo pacman -S --needed base-devel git --noconfirm

    cd ~
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm

    if command -v yay &> /dev/null; then
        echo "Yay has been successfully installed."
    else
        echo "Failed to install yay."
        exit 1
    fi
fi

echo -e "\n\e[36m [2/18]\e[0m Checking and enabling multilib repository...\n"
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib repository..."
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    echo "Enabled."
else
    echo "Multilib repository is already enabled. (SKIPPED)"
fi

echo -e "\n\e[36m [3/18]\e[0m Updating the system...\n"
sudo pacman -Syu --noconfirm

echo -e "\n\e[36m [4/18]\e[0m Checking if Steam is installed...\n"
if ! command -v steam &> /dev/null; then
    echo "Steam is not installed. Installing Steam..."
    sudo pacman -S steam --noconfirm
else
    echo "Steam is already installed. (SKIPPED)"
fi

echo -e "\n\e[36m [5/18]\e[0m Installing gamescope-session-steam-git from AUR...\n"
yay -S --aur gamescope-session-steam-git --noconfirm --sudoloop || paru -S --aur gamescope-session-steam-git --noconfirm


CONFIG_FILE="/etc/plasmalogin.conf"
echo "[6/18] Configuring auto-login for Plasma Login Manager..."
sudo tee /etc/plasmalogin.conf > /dev/null <<EOF
[Autologin]
Relogin=true
Session=$selected_de
User=$(whoami)
EOF

echo "Autologin configured for user: $(whoami)"

echo -e "\n\e[36m [7/18]\e[0m Creating /usr/bin/steamos-session-select\n"

echo '#!/usr/bin/bash

CONFIG_FILE="/etc/plasmalogin.conf"

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
        echo "Plasma Login Manager config file could not be found at $CONFIG_FILE."
        exit 1
    fi
    NEW_SESSION='$selected_de' # For other desktops, change here.
    sudo sed -i "s/^Session=.*/Session=${NEW_SESSION}/" "$CONFIG_FILE"
    steam -shutdown

# If the argument is "gamescope"
elif [ "$1" == "gamescope" ]; then
    
    echo "Switching session to Gamescope."
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Plasma Login Manager config file could not be found at $CONFIG_FILE."
        exit 1
    fi
    NEW_SESSION="gamescope-session-steam"
    sudo sed -i "s/^Session=.*/Session=${NEW_SESSION}/" "$CONFIG_FILE"
    dbus-send --session --type=method_call --print-reply --dest=org.kde.Shutdown /Shutdown org.kde.Shutdown.logout || gnome-session-quit --logout --no-prompt || cinnamon-session-quit --logout --no-prompt || loginctl terminate-session $XDG_SESSION_ID
else
    echo "Valid arguments are: plasma, gamescope."
    exit 1
fi' | sudo tee /usr/bin/steamos-session-select > /dev/null

echo -e "\n\e[36m [8/18]\e[0m Making /usr/bin/steamos-session-select executable...\n"
sudo chmod +x /usr/bin/steamos-session-select

echo -e "\n\e[36m [9/18]\e[0m Creating Plasma Login Manager sudoers rule...\n"
sudoers_file="/etc/sudoers.d/sddm_config_edit"
if [ ! -f "$sudoers_file" ]; then
    echo "ALL ALL=(ALL) NOPASSWD: /usr/bin/sed -i s/^Session=*/Session=*/ ${CONFIG_FILE}" | sudo tee "$sudoers_file" > /dev/null
    sudo chmod 440 "$sudoers_file"
else
    echo "Sudoers rule already set. (SKIPPED)"
fi


echo -e "\n\e[36m [10/18]\e[0m Installing MangoHUD\n"
if ! pacman -Qs mangohud > /dev/null; then
    
    sudo pacman -S mangohud --noconfirm
else
    echo "MangoHUD is already installed. (SKIPPED)"
fi

echo -e "\n\e[36m [11/18]\e[0m Installing wget\n"
if ! pacman -Qs wget > /dev/null; then
    
    sudo pacman -S wget --noconfirm
else
    echo "wget is already installed (SKIPPED)."
fi

echo -e "\n\e[36m [12/18]\e[0m Installing ntfs-3g (for NTFS partitions)\n"
if ! pacman -Qs ntfs-3g > /dev/null; then
    
    sudo pacman -S ntfs-3g --noconfirm
else
    echo "ntfs-3g is already installed (SKIPPED)."
fi

echo -e "\n\e[36m [13/18]\e[0m Installing Gamescope\n"
if ! pacman -Qs gamescope > /dev/null; then
    
    sudo pacman -S gamescope --noconfirm
else
    echo "Gamescope is already installed (SKIPPED)."
fi

echo -e "\n\e[36m [14/18]\e[0m Creating backlight rule for handheld devices\n"
sudo usermod -a -G video $(whoami)
if ! grep -q 'ACTION=="add", SUBSYSTEM=="backlight"' /etc/udev/rules.d/backlight.rules; then
    echo 'ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness"' | sudo tee -a /etc/udev/rules.d/backlight.rules
fi
echo -e "\n\e[36m [15/18]\e[0m Creating Gaming Mode shortcut icon...\n"

mkdir ~/arch-deckify
if [ ! -f ~/arch-deckify/steam-gaming-return.png ]; then
  wget -P ~/arch-deckify/ https://raw.githubusercontent.com/unlbslk/arch-deckify/refs/heads/main/icons/steam-gaming-return.png
else
  echo "Icon already exists. (SKIPPED)"
fi
if [ ! -f ~/arch-deckify/helper.png ]; then
  wget -P ~/arch-deckify/ https://raw.githubusercontent.com/unlbslk/arch-deckify/refs/heads/main/icons/helper.png
else
  echo "Icon already exists. (SKIPPED)"
fi

# Desktop icon
if [ ! -e "$(xdg-user-dir DESKTOP)/Return_to_Gaming_Mode.desktop" ]; then
    echo "[Desktop Entry]
    Name=Gaming Mode
    Exec=steamos-session-select gamescope
    Icon=$HOME/arch-deckify/steam-gaming-return.png
    Terminal=false
    Type=Application
    StartupNotify=false" > "$(xdg-user-dir DESKTOP)/Return_to_Gaming_Mode.desktop"
fi

if [ ! -e "$(xdg-user-dir DESKTOP)/Deckify_Tools.desktop" ]; then
    echo "[Desktop Entry]
    Name=Deckify Helper
    Exec=bash -c 'curl -sSL https://raw.githubusercontent.com/unlbslk/arch-deckify/refs/heads/main/gui_helper.sh | bash'
    Icon=$HOME/arch-deckify/helper.png
    Terminal=true
    Type=Application
    StartupNotify=false" > "$(xdg-user-dir DESKTOP)/Deckify_Tools.desktop"
fi

chmod +x "$(xdg-user-dir DESKTOP)/Return_to_Gaming_Mode.desktop"
chmod +x "$(xdg-user-dir DESKTOP)/Deckify_Tools.desktop"

# Application
if [ ! -e "/usr/share/applications/Return_to_Gaming_Mode.desktop" ]; then
    echo "[Desktop Entry]
    Name=Gaming Mode
    Exec=steamos-session-select gamescope
    Icon=$HOME/arch-deckify/steam-gaming-return.png
    Terminal=false
    Type=Application
    StartupNotify=false" > "$(xdg-user-dir)/Return_to_Gaming_Mode.desktop"
    chmod +x "$(xdg-user-dir)/Return_to_Gaming_Mode.desktop"
    sudo cp "$(xdg-user-dir)/Return_to_Gaming_Mode.desktop" "/usr/share/applications/"
    rm -rf "$(xdg-user-dir)/Return_to_Gaming_Mode.desktop"
fi

if [ ! -e "/usr/share/applications/Deckify_Tools.desktop" ]; then
    echo "[Desktop Entry]
    Name=Deckify Helper
    Exec=bash -c 'curl -sSL https://raw.githubusercontent.com/unlbslk/arch-deckify/refs/heads/main/gui_helper.sh | bash'
    Icon=$HOME/arch-deckify/helper.png
    Terminal=true
    Type=Application
    StartupNotify=false" > "$(xdg-user-dir)/Deckify_Tools.desktop"
    chmod +x "$(xdg-user-dir)/Deckify_Tools.desktop"
    sudo cp "$(xdg-user-dir)/Deckify_Tools.desktop" "/usr/share/applications/"
    rm -rf "$(xdg-user-dir)/Deckify_Tools.desktop"
fi

echo -e "\n\e[36m [16/18]\e[0m 'Return to Gaming Mode' and 'Helper' shortcut has been added to desktop and application menu.\n"

sudo pacman -S bluez bluez-utils --noconfirm
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service
echo -e "\n\e[36m [17/18]\e[0m Bluetooth service enabled and started.\n"


update_script_path="$HOME/arch-deckify/system_update.sh"
cat <<EOL > "$update_script_path"
#!/bin/bash
AUR_HELPER=""; UPDATE_CMD=""; command -v yay &>/dev/null && AUR_HELPER="yay" && UPDATE_CMD="yay -Syu --sudoloop --noconfirm" || { command -v paru &>/dev/null && AUR_HELPER="paru" && UPDATE_CMD="paru -Syu --noconfirm"; }; [ -z "\$AUR_HELPER" ] && echo -e "\e[91mError: Neither yay nor paru is installed.\e[0m" && sleep 10 && exit 1; (konsole -e bash -c "clear; echo -e '\n\n\e[94mEnter your sudo password:\nYou can open keyboard by pressing GUIDE+X or PS+SQUARE on controller.\n\n\e[0m'; sudo rm -rf /var/lib/pacman/db.lck; \$UPDATE_CMD; echo -e '\n\e[96mSystem packages have been updated.\e[0m'; if flatpak --version &>/dev/null; then echo -e '\n\e[96mUpdating Flathub...\e[0m'; flatpak update -y; echo -e '\e[93mFlatpak updated.\e[0m'; else echo 'Skipped Flatpak.'; fi; echo -e '\e[93mFinished. This window will be closed in 5 seconds...\e[0m'; sleep 5; exit") || (gnome-terminal -- bash -c "clear; echo -e '\n\n\e[94mEnter your sudo password:\nYou can open keyboard by pressing GUIDE+X or PS+SQUARE on controller.\n\n\e[0m'; sudo rm -rf /var/lib/pacman/db.lck; \$UPDATE_CMD; echo -e '\e[96mSystem packages have been updated.\e[0m'; if flatpak --version &>/dev/null; then echo -e '\n\e[96mUpdating Flathub...\e[0m'; flatpak update -y; echo -e '\e[93mFlatpak updated.\e[0m'; else echo 'Skipped Flatpak.'; fi; echo -e '\n\e[93mExecuted. This window will be closed in 5 seconds...\e[0m\n'; sleep 5; exit") || (kgx -- bash -c "clear; echo -e '\n\n\e[94mEnter your sudo password:\nYou can open keyboard by pressing GUIDE+X or PS+SQUARE on controller.\n\n\e[0m'; sudo rm -rf /var/lib/pacman/db.lck; \$UPDATE_CMD; echo -e '\e[96mSystem packages have been updated.\e[0m'; if flatpak --version &>/dev/null; then echo -e '\n\e[96mUpdating Flathub...\e[0m'; flatpak update -y; echo -e '\e[93mFlatpak updated.\e[0m'; else echo 'Skipped Flatpak.'; fi; echo -e '\n\e[93mExecuted. This window will be closed in 5 seconds...\e[0m\n'; sleep 5; pkill kgx") || (kitty bash -c "clear; echo -e '\n\n\e[94mEnter your sudo password:\nYou can open keyboard by pressing GUIDE+X or PS+SQUARE on controller.\n\n\e[0m'; sudo rm -rf /var/lib/pacman/db.lck; \$UPDATE_CMD; echo -e '\e[96mSystem packages have been updated.\e[0m'; if flatpak --version &>/dev/null; then echo -e '\n\e[96mUpdating Flathub...\e[0m'; flatpak update -y; echo -e '\e[93mFlatpak updated.\e[0m'; else echo 'Skipped Flatpak.'; fi; echo -e '\n\e[93mExecuted. This window will be closed in 5 seconds...\e[0m\n'; sleep 5; exit") || (alacritty -e bash -c "clear; echo -e '\n\n\e[94mEnter your sudo password:\nYou can open keyboard by pressing GUIDE+X or PS+SQUARE on controller.\n\n\e[0m'; sudo rm -rf /var/lib/pacman/db.lck; \$UPDATE_CMD; echo -e '\e[96mSystem packages have been updated.\e[0m'; if flatpak --version &>/dev/null; then echo -e '\n\e[96mUpdating Flathub...\e[0m'; flatpak update -y; echo -e '\e[93mFlatpak updated.\e[0m'; else echo 'Skipped Flatpak.'; fi; echo -e '\n\e[93mExecuted. This window will be closed in 5 seconds...\e[0m\n'; sleep 5; exit")
EOL
chmod +x "$update_script_path"
echo -e "\n\e[36m [18/18]\e[0m 'system_update.sh' has been added to $update_script_path\n"
echo -e "\n\n\e[1;33mInstallation is complete. We recommend you to reboot your system.\e[0m"
echo -e "\n\e[1;30mIf you encounter an issue (such as being stuck on a black screen), check here:\e[0m https://unlbslk.github.io/arch-deckify/issues/"
echo -e "\n\e[37mYou can update the system in Steam by adding the ~/arch-deckify/system_update.sh file to Steam as a non-Steam game while in desktop mode.\nUnfortunately, system updates are not possible through Steam settings.\e[0m\n\n"
