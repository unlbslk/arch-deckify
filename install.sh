#!/bin/bash

if [ "$EUID" -eq 0 ]; then
    echo -e "\e[91mERROR:\e[0m Run this script WITHOUT root/sudo privileges."
    exit 1
fi

echo -e "\e[1;33mWelcome to Arch SteamOS Script\e[0m"
echo -e "\e[91mWarning: This script mostly does not work on NVIDIA cards.\e[0m"
echo -e "\e[37mThis script has been made to work only on SDDM.\e[0m"
echo -e "\e[37mYou must make additional changes for other display managers.\e[0m"

if ! pacman -Qs sddm > /dev/null; then
    echo "SDDM is not installed. (EXITING)"
    exit 1
else
    echo "SDDM is installed."
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


echo "[1/17] Checking if yay is installed..."
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
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
else
    echo "Yay is already installed. (SKIPPED)"
fi

echo "[2/17] Checking and enabling multilib repository..."
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib repository..."
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    echo "Enabled."
else
    echo "Multilib repository is already enabled. (SKIPPED)"
fi

echo "[3/17] Updating the system..."
sudo pacman -Syu --noconfirm

echo "[4/17] Checking if Steam is installed..."
if ! command -v steam &> /dev/null; then
    echo "Steam is not installed. Installing Steam..."
    sudo pacman -S steam --noconfirm
else
    echo "Steam is already installed. (SKIPPED)"
fi

echo "[5/17] Installing gamescope-session-steam-git using yay..."
yay -S gamescope-session-steam-git --noconfirm --sudoloop

echo "[6/17] Configuring auto-login for SDDM..."

sudo sed -i "s/^Relogin=false/Relogin=true/; s/^User=.*/User=$(whoami)/" /etc/sddm.conf.d/kde_settings.conf

echo "Autologin configured for user: $(whoami)"

echo "[7/17] Creating /usr/bin/steamos-session-select"

echo '#!/usr/bin/bash

CONFIG_FILE="/etc/sddm.conf.d/kde_settings.conf"

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
        echo "SDDM config file could not be found at $CONFIG_FILE."
        exit 1
    fi
    NEW_SESSION='$selected_de' # For other desktops, change here.
    sudo sed -i "s/^Session=.*/Session=${NEW_SESSION}/" "$CONFIG_FILE"
    steam -shutdown

# If the argument is "gamescope"
elif [ "$1" == "gamescope" ]; then
    
    echo "Switching session to Gamescope."
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "SDDM config file could not be found at $CONFIG_FILE."
        exit 1
    fi
    NEW_SESSION="gamescope-session-steam"
    sudo sed -i "s/^Session=.*/Session=${NEW_SESSION}/" "$CONFIG_FILE"
    dbus-send --session --type=method_call --print-reply --dest=org.kde.Shutdown /Shutdown org.kde.Shutdown.logout || gnome-session-quit --logout --no-prompt || cinnamon-session-quit --logout --no-prompt || loginctl terminate-session $XDG_SESSION_ID
else
    echo "Valid arguments are: plasma, gamescope."
    exit 1
fi' | sudo tee /usr/bin/steamos-session-select > /dev/null

echo "[8/17] Making /usr/bin/steamos-session-select executable..."
sudo chmod +x /usr/bin/steamos-session-select

echo "[9/17] Making /etc/sddm.conf.d/kde_settings.conf editable without prompting sudo password..."
sudoers_file="/etc/sudoers.d/sddm_config_edit"
if [ ! -f "$sudoers_file" ]; then
    echo "ALL ALL=(ALL) NOPASSWD: /usr/bin/sed -i s/^Session=*/Session=*/ /etc/sddm.conf.d/kde_settings.conf" | sudo tee "$sudoers_file" > /dev/null
    sudo chmod 440 "$sudoers_file"
else
    echo "Passwordless sudo for editing /etc/sddm.conf.d/kde_settings.conf is already set. (SKIPPED)"
fi


echo "[10/17] Installing MangoHUD"
if ! pacman -Qs mangohud > /dev/null; then
    
    sudo pacman -S mangohud --noconfirm
else
    echo "MangoHUD is already installed (SKIPPED)."
fi

echo "[11/17] Installing wget"
if ! pacman -Qs wget > /dev/null; then
    
    sudo pacman -S wget --noconfirm
else
    echo "wget is already installed (SKIPPED)."
fi

echo "[12/17] Installing Gamescope"
if ! pacman -Qs gamescope > /dev/null; then
    
    sudo pacman -S gamescope --noconfirm
else
    echo "Gamescope is already installed (SKIPPED)."
fi

echo "[13/17] Installing xpadneo (driver for some gamepads)"
if ! pacman -Qs xpadneo > /dev/null; then
    yay -S xpadneo-dkms --noconfirm --sudoloop
else
    echo "Xpadneo is already installed (SKIPPED)."
fi

echo "[14/17] Downloading Gaming Mode shortcut icon..."

mkdir ~/arch-deckify
if [ ! -f ~/arch-deckify/steamdeck-gaming-return.png ]; then
  wget -P ~/arch-deckify/ https://raw.githubusercontent.com/unlbslk/arch-deckify/refs/heads/main/icons/steamdeck-gaming-return.png
else
  echo "Icon already exists. (SKIPPED)"
fi

# Desktop icon
if [ ! -e "$(xdg-user-dir DESKTOP)/Return_to_Gaming_Mode.desktop" ]; then
    echo "[Desktop Entry]
    Name=Gaming Mode
    Exec=steamos-session-select gamescope
    Icon=$HOME/arch-deckify/steamdeck-gaming-return.png
    Terminal=false
    Type=Application
    StartupNotify=false" > "$(xdg-user-dir DESKTOP)/Return_to_Gaming_Mode.desktop"
fi

chmod +x "$(xdg-user-dir DESKTOP)/Return_to_Gaming_Mode.desktop"

# Application
if [ ! -e "/usr/share/applications/Return_to_Gaming_Mode.desktop" ]; then
    echo "[Desktop Entry]
    Name=Gaming Mode
    Exec=steamos-session-select gamescope
    Icon=$HOME/arch-deckify/steamdeck-gaming-return.png
    Terminal=false
    Type=Application
    StartupNotify=false" > "~/Return_to_Gaming_Mode.desktop"
fi

chmod +x "~/Return_to_Gaming_Mode.desktop"

    sudo cp ~/Return_to_Gaming_Mode.desktop /usr/share/applications/
    rm -rf ~/Return_to_Gaming_Mode.desktop
fi

echo "[15/17] 'Return to Gaming Mode' has been added to desktop and application menu."

sudo pacman -S bluez bluez-utils --noconfirm
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service
echo "[16/17] Bluetooth service enabled and started."

if command -v flatpak &> /dev/null; then
    echo "Flatpak is already installed."
else
    echo -e "\n\n\e[95mWould you like to enable the Flathub repository? This will allow you to install applications from the Discover app. \e[0m"
    read -p "(y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        sudo pacman -S flatpak --noconfirm
        echo "Installed Flatpak."
    else
        echo "Skipped."
    fi
fi

if [ ! -f "${HOME}/homebrew/services/PluginLoader" ]; then
    echo -e "\n\n\e[40mmWant to install Decky Loader? With this, you can install plugins to your Steam interface.\e[0m"
    echo -e "\e[31mWARNING: \e[0mThis is an UNOFFICIAL project created by the community. It is not necessary for your system, and you may encounter issues while using it. The choice to install is entirely yours, and any potential problems or risks are your responsibility."
    read -p "(y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh
        sudo sed -i 's~TimeoutStopSec=.*$~TimeoutStopSec=2~g' /etc/systemd/system/plugin_loader.service
        sudo systemctl daemon-reload
        sudo systemctl restart plugin_loader.service
        echo "Installed Decky Loader."
    else
        echo "Skipped."
    fi
else
    echo "Decky Loader is already installed. (SKIPPED)"
fi


update_script_path="$HOME/arch-deckify/system_update.sh"
cat <<EOL > "$update_script_path"
#!/bin/bash

konsole -e bash -c "clear; echo -e '\n\n\e[94mEnter your sudo password:\nYou can open keyboard by pressing GUIDE+A or PS+SQUARE on controller.\n\n\e[0m'; sudo rm -rf /var/lib/pacman/db.lck; echo -e \"\n\e[93mPlease do not close before the update is finished.\e[0m\n\"; yay -Syu --sudoloop --noconfirm; echo -e '\e[96mSystem packages have been updated.\e[0m'; if flatpak --version &> /dev/null; then echo -e '\n\e[96mUpdating Flathub...\e[0m'; flatpak update -y; echo -e '\e[93mFlatpak updated.\e[0m'; else echo 'Skipped Flatpak.'; fi; echo -e \"\e[93mFinished. This window will be closed in 5 seconds...\e[0m\"; sleep 5; exit" || gnome-terminal -- bash -c "clear; echo -e '\n\n\e[94mEnter your sudo password:\nYou can open keyboard by pressing GUIDE+A or PS+SQUARE on controller.\n\n\e[0m'; sudo rm -rf /var/lib/pacman/db.lck; echo -e \"\e[93mPlease do not close before the update is finished.\e[0m\"; yay -Syu --sudoloop --noconfirm; echo -e '\e[96mSystem packages have been updated.\e[0m'; if flatpak --version &> /dev/null; then echo -e '\n\e[96mUpdating Flathub...\e[0m'; flatpak update -y; echo -e '\e[93mFlatpak updated.\e[0m'; else echo 'Skipped Flatpak.'; fi; echo -e \"\n\e[93mExecuted. This window will be closed in 5 seconds...\e[0m\n\"; sleep 5; exit"
EOL
chmod +x "$update_script_path"
echo "[17/17] 'system_update.sh' has been added to $update_script_path"
echo -e "\n\n\e[1;33mInstallation is complete. You can try by clicking Gaming Mode shortcut.\e[0m"
echo -e "\e[37mYou can update the system in Steam by adding the ~/arch-deckify/system_update.sh file to Steam as a non-Steam game while in desktop mode (Konsole or Gnome Terminal should be installed.). Unfortunately, system updates are not possible through Steam settings.\e[0m\n\n"
