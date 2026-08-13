Note: These dotfiles were made while using the distro Void Linux.

The following files need to be placed at the home directory, so at /home/<YOUR_USERNAME>:
- .xinitrc
- .fehbg
- .bashrc
- .bash_profile

Regarding xmonad, ghc version 9.8.4 was used

DEBIAN COMMANDS (if you are not using Debian, then use the equivalent command of the distro that you are using):

`sudo apt update && sudo apt install libghc-xmonad-contrib-dev xterm xmessage`

`sudo apt update && sudo apt install libghc-xmonad-dev `

`sudo apt install alacritty`

`sudo apt update && sudo apt install xmobar`

`sudo apt update && sudo apt install xcape x11-xmodmap brightnessctl`

VOID COMMANDS (if you are not using Void Linux, then use the equivalent command of the distro that you are using):
The following package is needed for clicking on a workspace in xmobar (note: xbps-install is command in Void Linux to install a package):
`sudo xbps-install -S xdotool`

Furthermore, the following script needs to become an executable, which can be done by doing the following:
`chmod +x ~/.config/xmonad/scripts/keys.sh`

Instead of manually invoking the keys.sh via a shortcut (the shortcut can be read in xmonad.hs), you can also do this:

If you want a keyboard setup to apply the second you log into your computer so you don't have to press that shortcut every time, add it to your startupHook inside your xmonad.hs like this:

`, startupHook        = do
    spawnOnce "feh --bg-fill /home/zaky/Pictures/motorcycle_restaurant.jpg"
    spawnOnce "sh ~/.config/xmonad/scripts/keys.sh"`


Regarding extra keybinds that are added as a modifier, xmodmap (version 1.0.11_1) and xcap (version 1.2_2) were used in order to make that possible. Moreover, I tab (when holding the button), backslash (when holding the button) and the Windows key as my modifiers. 

After downloading all the the required packages, run the following command to compile xmonad that you can use it:
xmonad --recompile

### Emacs
I downloaded this python debugger in Debian via the following command:

`sudo apt install python3-debugpy`

For the IDE engine (eglot) to underline errors and know your method names, it requires a Python language server installed on your system. Open your system terminal and install the following:

`sudo apt update`

`sudo apt install python3-lsp-server`

`sudo apt install pipx`

`pipx ensurepath`

`pipx install pyright`

`pyright --version`


## FYI
mimeapps.list is used to configure, for example, Zathura as the standard for opening PDF files.
