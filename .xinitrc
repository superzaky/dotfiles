# Set screen layout: Monitor on top, Laptop on bottom
xrandr --output HDMI-1 --auto --output eDP-1 --auto --below HDMI-1 &

# sxhkd &
# exec bspwm
# exec dbus-run-session bspwm

# MODIFIER KEYS
# 1. Clear any existing mappings to avoid conflicts
xmodmap -e "keycode 23 = Tab"
xmodmap -e "keycode 51 = backslash"

# 2. Map the keys to the Super_L (Mod4) modifier
# This tells the system: when held, these are Windows keys
xmodmap -e "keycode 23 = Super_L"
xmodmap -e "keycode 51 = Super_L"

# 3. Make sure Super_L is actually recognized as Mod4
xmodmap -e "add mod4 = Super_L"

# 4. Use xcape to handle the "Tap" functionality
# This tells the system: if Super_L is pressed and released quickly, 
# send 'Tab' or 'backslash' instead.
killall xcape # Restart xcape to apply new settings
xcape -e "Super_L=Tab;Super_L=backslash"


# Start XMonad
exec dbus-run-session xmonad