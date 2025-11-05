## Install Arch-Deckify
- To start the installation, open a terminal window and run the following command:
```bash
bash <(curl -sSL https://raw.githubusercontent.com/unlbslk/arch-deckify/refs/heads/main/install.sh)
```

- After you enter your sudo password, the script will ask you which desktop environment you want to use as desktop mode:
![Installation](images/installation.png)
!!! info
	If the installation fails because SDDM is not found, see [how to install SDDM](issues.md#what-is-the-sddm-and-how-can-i-install-it).

**During installation, the following will happen in order:**

- If an AUR helper (yay/paru) is not installed on the system, `yay` will be installed automatically.
- If Arch Linux's `multilib` repository is not enabled on your system, it will be automatically enabled and the system will be updated (for syncing repos).
- If Steam is not installed on your system, it will be automatically downloaded from the `multilib` repository.
!!! warning
	If you've previously downloaded Steam from Flathub, the script may cause issues. Try downloading from the Multilib repository.
- Installs gamescope-session-steam-git from the AUR (includes gamescope and other dependencies).
- Generates an sddm.conf file in /etc/ to enable autologin and session switching.
- Adds a sudoers rule to allow session switching without a password.
- Creates a `steamos-session-select` file, allowing switching back to desktop mode from within Steam.
- Installs these packages: gamescope, mangohud(for FPS counter), wget, ntfs-3g(for NTFS drive support)
- Adds a udev rule for backlight control, enabling brightness adjustment within Steam.
- Creates desktop and application shortcuts for Gaming Mode and a GUI Helper, adds a system update script, and enables Bluetooth services.

If the installation is successful, these shortcuts will be added to your desktop `(~/Desktop)` and applications `(/usr/share/applications)`:

![Shortcuts](images/shortcuts.png)
!!! info
	The GUI Helper allows you to manually install additional tools like Decky Loader. Look [GUI Helper](guihelper.md) for more information.

!!! warning
	If you get stuck on a black screen when you click the Gaming Mode shortcut, see the [stuck on a black screen](issues.md#stuck-on-a-black-screen-cannot-return-to-desktop-again) section to return to the desktop again.

