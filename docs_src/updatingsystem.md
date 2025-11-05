# Updating System
!!! info
    System updates cannot be performed directly through Steam settings.
- The update from Steam settings is made to work on immutable distributions such as SteamOS.
- It is not possible to do this in a *mutable* distribution like Arch Linux.
- The Arch Deckify script creates a script that allows you to perform a system update to `~/arch-deckify/system_update.sh`.
- By adding this script to Steam as a *non-Steam game*, you can update the system from Gaming Mode.
![system_update.sh script](images/systemupdate.png)
!!! warning
    In order for the system update script to work, at least one of the supported terminal emulators `(konsole, gnome-terminal, kitty, alacritty)` must be installed.
    
    Depending on the distribution you are using, at least one of these usually comes installed.

- This script automatically updates system packages first, then AUR packages, and finally Flathub packages if any are installed.
- The script closes automatically when the update is completed.

!!! info
    It is recommended that you pause Steam downloads during the update.

    If the `Allow Downloads During Gameplay` option is disabled in Steam settings (disabled by default), downloads will automatically pause.