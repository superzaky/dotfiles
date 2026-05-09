#!/bin/bash

# Start with dual screens by default
~/.config/xmonad/scripts/dual_screen.sh &

# sxhkd &
# exec bspwm
# exec dbus-run-session bspwm

# MODIFIER KEYS 
~/.config/xmonad/scripts/keys.sh &

# Start XMonad
exec dbus-run-session xmonad