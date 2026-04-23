# Set screen layout: Monitor on top, Laptop on bottom
xrandr --output HDMI-1 --auto --output eDP-1 --auto --below HDMI-1 &

# sxhkd &
# exec bspwm
# exec dbus-run-session bspwm

# Start XMonad
exec dbus-run-session xmonad