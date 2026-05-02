# Set screen layout: Monitor on top, Laptop on bottom
xrandr --output HDMI-1 --auto --output eDP-1 --auto --below HDMI-1 &

# sxhkd &
# exec bspwm
# exec dbus-run-session bspwm

# MODIFIER KEYS
# 1. Reset everything
setxkbmap -layout us
killall xcape 2>/dev/null

# 2. Create a "spare" backslash on an invisible key (e.g., keycode 248)
# This ensures the system knows what a backslash is, even if 51 is busy.
xmodmap -e "keycode 248 = backslash"
xmodmap -e "keycode 249 = Tab"

# 3. Map physical keys to the Modifiers
xmodmap -e "keycode 23 = Super_L"
xmodmap -e "keycode 51 = Super_R"
xmodmap -e "add mod4 = Super_L"
xmodmap -e "add mod4 = Super_R"

# 4. Tell xcape to use those "spare" keys when you tap
# We use the keysym names here
xcape -t 200 -e "Super_L=Tab;Super_R=backslash"

# Start XMonad
exec dbus-run-session xmonad