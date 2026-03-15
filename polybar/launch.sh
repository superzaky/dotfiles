#!/usr/bin/env bash

# Terminate already running bar instances
pkill -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch the bar named "example"
polybar example &