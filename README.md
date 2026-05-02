Note: These dotfiles were made while using the distro Void Linux.

The following files need to be placed at the home directory, so at /home/<YOUR_USERNAME>:
- .xinitrc
- .fehbg
- .bashrc
- .bash_profile

Regarding xmonad, ghc version 9.8.4 was used

The following package is needed for clicking on a workspace in xmobar (note: xbps-install is command in Void Linux to install a package):
sudo xbps-install -S xdotool


Regarding extra keybinds that are added as a modifier, xmodmap (version 1.0.11_1) and xcap (version 1.2_2) were used in order to make that possible. Moreover, I tab (when holding the button), backslash (when holding the button) and the Windows key as my modifiers. 
