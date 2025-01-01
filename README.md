# Arch-Deckify
A script to easily set up a SteamOS-like gaming environment on Arch Linux.
This script is designed to bring SteamOS-style session switching to Arch Linux. It automates the installation and setup of a **Gaming Mode (Gamescope)** and a **Desktop Mode (Wayland session)**, along with configuration for **SDDM** and several optional components.

## Features:
- **Wayland Session Selector**: Allows you to choose a desktop session for your system.
- **Gamescope Gaming Mode**: Switch to a full-screen gaming experience similar to SteamOS.
- **SDDM Configuration**: Automatically configures SDDM for autologin.
- **Shortcut Creation**: Adds a desktop shortcut for easy switching to Gaming Mode.
- **Optional Tools**: Offers installation of **Flatpak**, **Decky Loader**.
- **Session Switcher**: Shortcuts to easily switch between desktop and game mode.

## Requirements:
- Arch Linux (or an Arch-based distribution)
- SDDM display manager
- A compatible GPU (NVIDIA hardware may face issues)
- KDE Plasma Desktop (<ins>Other desktops are also supported</ins>, but KDE Plasma is recommended for the best experience.)


## How to install?

**Run this code in your terminal:**
```bash
curl -L https://raw.githubusercontent.com/unlbslk/arch-deckify/refs/heads/main/install.sh | sh
```

## ⚠️ Important Notice (READ BEFORE INSTALLING)

Please note that running this script may modify important system configurations, files, and settings. In some cases, it could lead to system instability, configuration loss, or make the system unbootable. Restoring the system to a working state may require advanced technical knowledge. Before executing directly, check the content of the script.

By using this script, you acknowledge that **you** are fully responsible for any issues that arise, including but not limited to data loss, system corruption, or any unforeseen consequences. It is highly recommended that you back up your important data and configurations before proceeding. Use this script at your own risk. 


### Session Switching
**The** `steamos-session-select` **command allows you to switch between Gamescope (Gaming Mode) and your selected Wayland session. Example usage:**
```bash
steamos-session-select gamescope  # Switch to Gaming Mode
steamos-session-select desktop     # Switch to Desktop (to your selected session)
```
You can also switch between Gaming Mode and Desktop Mode easily using the Steam interface or the desktop shortcut created during setup.

### Change Default Desktop
**To change the session used when switching to Desktop Mode, run the following script:**
```bash
curl -L https://raw.githubusercontent.com/unlbslk/arch-deckify/refs/heads/main/change_default_desktop.sh | sh
```

### Decky Plugin Loader
The Decky Loader is an **unofficial** community-driven tool that allows you to install and manage plugins for your Steam interface. While not essential for system functionality, it provides additional customization options for SteamOS. (https://decky.xyz/)
Please note that it is **not an official tool** and may cause issues. Any potential risks or problems are the user's responsibility.

**To install Decky Loader:**
```bash
curl -L https://raw.githubusercontent.com/unlbslk/arch-deckify/refs/heads/main/setup_deckyloader.sh | sh
```
**To remove Decky Loader:**
```bash
curl -L https://raw.githubusercontent.com/unlbslk/arch-deckify/refs/heads/main/remove_deckyloader.sh | sh
```

## Disclaimer

All logos, trademarks, and names related to **Steam**, **SteamOS**, **Steam Deck**, **Valve**, and other software such as **Plasma** and **Arch** are the property of their respective owners. These logos and names are used for reference and informational purposes only. This project is not affiliated with, endorsed, or sponsored by **Valve**, **Steam**, **SteamOS**, **Steam Deck**, **Plasma**, **Arch Linux**, **Decky Loader** or any of their respective organizations. All rights reserved to the original trademark holders.
