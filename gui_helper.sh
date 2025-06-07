#!/bin/bash

# Decky Loader path
PLUGIN_LOADER_PATH="${HOME}/homebrew"

ask_sudo() {
    if sudo -n true 2>/dev/null; then
        return 0
    fi

    while true; do
        PASSWORD=$(zenity --password --title="Authentication Required")
        echo "$PASSWORD" | sudo -S -v >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            export PASSWORD
            return 0
        else
            zenity --error --text="Wrong password. Please try again."
        fi
    done
}

# Use password to run sudo command
run_with_sudo() {
    echo "$PASSWORD" | sudo -S "$@"
}

# Check is zenity installed
if ! pacman -Qs zenity > /dev/null; then
    ask_sudo
    run_with_sudo pacman -S zenity --noconfirm
fi

while true; do
    allTools=(
        "Update System" "Updates all system packages"
        "Change Default Desktop" "Set your preferred desktop session"
    )

    if [ ! -d "$PLUGIN_LOADER_PATH" ]; then
        allTools+=("Install Decky Loader" "Install plugin loader for Steam")
    else
        allTools+=("Reinstall Decky Loader" "Reinstall plugin loader for Steam")
        allTools+=("Remove Decky Loader" "Remove plugin loader for Steam")
    fi

    if ! flatpak remote-list 2>/dev/null | grep -q '^flathub'; then
        allTools+=("Install Flathub" "Enable GUI application support")
    fi
    allTools+=("Additional Settings" "Additional settings for your system")
    allTools+=("Uninstall Script" "Uninstall Arch Deckify script")
    params=()
    for ((i=0; i<${#allTools[@]}; i+=2)); do
        params+=("FALSE" "${allTools[i]}" "${allTools[i+1]}")
    done

    SELECTION=$(zenity --title "Deckify Helper" \
        --list --radiolist \
        --height=500 --width=600 \
        --text="Please select the action you want to perform:" \
        --column "" --column "Component" --column "Description" \
        "${params[@]}")

    if [ $? -ne 0 ]; then
        echo "Cancelled."
        exit 1
    fi

    case "$SELECTION" in
        "Update System")
            ask_sudo
            (
            echo "# Updating system packages..."
            yay -Syu --noconfirm --sudoloop || paru -Syu --noconfirm
            if flatpak --version &> /dev/null; then echo "# Updating flatpak packages..."; flatpak update -y; fi
            ) | zenity --progress --title="Updating System" --width=500 --auto-close --pulsate --no-cancel
            zenity --info --text="System was updated."
            ;;
        "Change Default Desktop")
    mapfile -t available_desktops < <(ls /usr/share/wayland-sessions/*.desktop 2>/dev/null | sed 's|/usr/share/wayland-sessions/||; s/\.desktop$//' | grep -v gamescope)

    if [ ${#available_desktops[@]} -eq 0 ]; then
        zenity --error --text="No desktop sessions found."
        break
    fi

    params=()
    for session in "${available_desktops[@]}"; do
        params+=("$session" "$session")
    done

    while true; do
        selected_de=$(zenity --list --radiolist --title="Select Default Desktop" \
            --height=400 --width=400 \
            --text="Choose your default desktop session:" \
            --column "Select" --column "Session" "${params[@]}")

        if [ $? -ne 0 ]; then
            break
        fi

        if [ -z "$selected_de" ]; then
            zenity --warning --text="Please select a desktop."
            continue
        fi

        break
    done

    if [ -z "$selected_de" ]; then
        break
    fi

    tmpfile=$(mktemp)
    trap 'rm -f "$tmpfile"' EXIT
    echo '#!/usr/bin/bash
if [ -f /etc/sddm.conf.d/kde_settings.conf ]; then
    CONFIG_FILE="/etc/sddm.conf.d/kde_settings.conf"
else
    CONFIG_FILE="/usr/lib/sddm/sddm.conf.d/default.conf"
fi

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
fi' | sudo tee $tmpfile > /dev/null


    ask_sudo
    run_with_sudo mv "$tmpfile" /usr/bin/steamos-session-select
    run_with_sudo chmod +x /usr/bin/steamos-session-select
    zenity --info --text="Default desktop session set to '${selected_de}'"
    ;;

        "Install Decky Loader")
            zenity --question --title="Install Decky Loader" \
                --text="Install the Decky Loader?\n\nThis is an UNOFFICIAL tool to enhance Steam with plugins. Proceed with caution."

            if [ $? -eq 0 ]; then
                ask_sudo
                (
                    echo "# Installing dependencies..."
                    run_with_sudo pacman -S jq --noconfirm
                    echo "# Executing install script..."
                    curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh
                    echo "# Restarting systemd service..."
                    run_with_sudo systemctl daemon-reexec
                    run_with_sudo systemctl restart plugin_loader.service
                ) | zenity --progress --title="Installing Decky Loader" --width=500 --auto-close --pulsate --no-cancel

                if [ -d "$PLUGIN_LOADER_PATH" ]; then
                    zenity --info --text="Decky Loader installed successfully."
                else
                    zenity --error --text="Decky Loader installation failed."
                fi
            fi
            ;;
        "Reinstall Decky Loader")
            ask_sudo
            (
                echo "# Installing dependencies..."
                run_with_sudo pacman -S jq --noconfirm
                echo "# Executing install script..."
                curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh
                echo "# Restarting systemd service..."
                run_with_sudo systemctl daemon-reexec
                run_with_sudo systemctl restart plugin_loader.service

            ) | zenity --progress --title="Reinstalling Decky Loader" --width=500 --auto-close --pulsate --no-cancel
            if [ -d "$PLUGIN_LOADER_PATH" ]; then
                zenity --info --text="Decky Loader reinstalled successfully."
            else
                zenity --error --text="Decky Loader reinstallation failed."
            fi
            ;;
        "Remove Decky Loader")

            ask_sudo
            (
            echo "# Running uninstall script..."
            curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/uninstall.sh | sh
            run_with_sudo systemctl stop plugin_loader.service
            run_with_sudo rm -rf "${HOME}/homebrew"
            ) | zenity --progress --title="Uninstalling Decky Loader" --width=500 --auto-close --pulsate --no-cancel
            zenity --info --text="Decky Loader uninstalled."
            ;;
        "Uninstall Script")
            zenity --question --title="Uninstall Deckify Script" \
                --text="Are you sure to uninstall this script?\n\nThese will be REMOVED from your system (if installed):\n\n- Gamescope session\n- Gamescope package\n- Decky Loader\n- Gaming mode shortcuts\n- SDDM autologin (will be disabled)\n\nThese will NOT BE REMOVED from your system:\n\n- Steam\n- MangoHUD\n- Flatpak\n- Yay/Paru (AUR Helper)\n- ntfs-3g (NTFS Drivers)\n- Bluetooth services\n- KDE Plasma configs/themes etc."

            if [ $? -eq 0 ]; then
                ask_sudo
                (
                echo "# Removing gamescope-session-steam-git..."
                yay -Rns --noconfirm gamescope-session-steam-git || paru -Rns --noconfirm gamescope-session-steam-git
                sleep 1
                echo "# Removing arch-deckify..."
                run_with_sudo rm -rf "/etc/sudoers.d/sddm_config_edit"
                rm -rf "${HOME}/arch-deckify"
                sleep 1
                echo "# Removing gamescope..."
                run_with_sudo pacman -R gamescope
                echo "# Removing shortcuts.."
                rm -rf "$(xdg-user-dir DESKTOP)/Return_to_Gaming_Mode.desktop"
                rm -rf "/usr/share/applications/Return_to_Gaming_Mode.desktop"
                rm -rf "$(xdg-user-dir DESKTOP)/Deckify_Tools.desktop"
                rm -rf "/usr/share/applications/Deckify_Tools.desktop"
                sleep 1
                if [ -d "$HOME/homebrew" ]; then
                    echo "# Uninstalling Decky Loader..."
                    curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/uninstall.sh | sh
                    run_with_sudo systemctl stop plugin_loader.service
                    run_with_sudo rm -rf "${HOME}/homebrew"
                else
                    echo "Decky Loader is not installed."
                fi
                echo "# Disabling SDDM autologin..."
                if [ -f /etc/sddm.conf.d/kde_settings.conf ]; then
                    CONFIG_FILE="/etc/sddm.conf.d/kde_settings.conf"
                else
                    CONFIG_FILE="/usr/lib/sddm/sddm.conf.d/default.conf"
                fi
                sudo sed -i "s/^Relogin=true/Relogin=false/; s/^User=.*/User=/; s/^Session=.*/Session=/" "$CONFIG_FILE"
                sleep 1
                ) | zenity --progress --title="Uninstalling Script" --width=500 --auto-close --pulsate --no-cancel
                zenity --info --text="Deckify Script was uninstalled."
                exit
            fi
            ;;
        "Install Flathub")
            ask_sudo
            (
                echo "# Installing Flatpak and Flathub..."
                run_with_sudo pacman -S flatpak --noconfirm
                run_with_sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            ) | zenity --progress --title="Installing Flathub" --width=500 --auto-close --pulsate --no-cancel

            if flatpak remote-list | grep -q '^flathub'; then
                zenity --info --text="Flathub installed successfully."
            else
                zenity --error --text="Failed to install Flathub."
            fi
            ;;
        "Additional Settings")
            ADDSET_SELECTION=$(zenity --title "Deckify Additional Settings" \
                --list --radiolist \
                --height=500 --width=600 \
                --text="Please select the action you want to perform:" \
                --column "" --column "Component" --column "Description" \
                "FALSE" "Install KDE Presets" "Install SteamOS KDE Plasma themes/configs")
                case "$ADDSET_SELECTION" in
                "Install KDE Presets")
                    zenity --question --text="The latest SteamOS KDE presets will be installed from the link below:
https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/.
This includes themes like 'Vapor' and the 'Add to Steam' option for right-clicked apps, along with other settings that mirror SteamOS.
    Note: This is designed for SteamOS and may cause issues on your device.
⚠️ The downloaded file will merge with your system’s root directories (e.g., /etc/, /usr/). Conflicts may disrupt your system. Please check compatibility before proceeding.
Are you sure you want to continue?"

                if [ $? -eq 0 ]; then
                    ask_sudo
                    (
                    echo "# Looking for latest version..."
                    url="https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/"
                    files=$(curl -s "$url" | grep -oP 'steamdeck-kde-presets-[\d\.]+-[\d]+-any\.pkg\.tar\.zst')
                    latest=$(echo "$files" | sort -V | tail -n1)
                    if [ -z "$latest" ]; then
                        zenity --error --text="Cannot fetch the latest version of KDE presets."
                        exit 1
                    fi

                    echo "# Downloading latest version..."
                    echo "Latest steamdeck-kde-presets package is: $latest"
                    echo "Downloading..."
                    mkdir "${HOME}/arch-deckify"
                    curl -O "${HOME}/arch-deckify" "${url}${latest}"
                    echo "Downloaded: $latest"
                    echo "# Installing latest version..."
                    sudo tar -I zstd -xvf  "${HOME}/arch-deckify/${latest}" -C /
                    rm -rf "${HOME}/arch-deckify/${latest}"
                    ) | zenity --progress --title="Installing KDE Presets" --width=500 --auto-close --pulsate --no-cancel
                    zenity --info --text="KDE presets was installed."

                fi
                    ;;
                *)
                echo "Unknown selection."
                ;;
                esac

            ;;
        *)
            echo "Unknown selection."
            ;;
    esac
done
