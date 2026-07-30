#!/bin/bash

# IF THE FOLLOWING KEYS DO NO WORK, YOU PROBABLY DO NOT HAVE xcape installed. In that case do this if you are on Debian: sudo apt install xcape

# MODIFIER KEYS
# 1. Reset everything
setxkbmap -layout us
killall xcape 2>/dev/null

# 2. Create a "spare" backslash, tab, and caps lock on invisible keys
xmodmap -e "keycode 248 = backslash"
xmodmap -e "keycode 249 = Tab"
xmodmap -e "keycode 250 = Caps_Lock"

# 3. Map physical keys to Modifiers (do this before "add mod4", same order as before)
xmodmap -e "keycode 23 = Super_L"   # physical Tab key
xmodmap -e "keycode 51 = Super_R"
xmodmap -e "add mod4 = Super_L"
xmodmap -e "add mod4 = Super_R"

# Map Caps Lock (keycode 66) to behave like Control ---
# First, remove Caps_Lock from its lock modifier group
xmodmap -e "clear lock"
xmodmap -e "keycode 66 = Control_L"
xmodmap -e "add control = Control_L"

# 4. Tell xcape to use those "spare" keys when you tap. hold = modifier
# We add Control_L=Caps_Lock to our existing xcape command using a semicolon
xcape -t 200 -e "Super_L=Tab;Super_R=backslash;Control_L=Caps_Lock"
# xcape -t 200 -e "Super_R=backslash;Control_L=Caps_Lock"

# Set brightness to 5% on startup
brightnessctl set 5%
