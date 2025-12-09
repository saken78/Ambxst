#!/usr/bin/env bash

# Kill notification daemons that may conflict
for daemon in dunst mako swaync; do
  if pgrep -x "$daemon" >/dev/null; then
    echo "Stopping $daemon..."
    pkill -x "$daemon"
  fi
done

# hypridle
if pgrep -x "hypridle" >/dev/null; then
  echo "Stopping existing hypridle instances..."
  pkill -x "hypridle"
  sleep 0.5
fi

if command -v hypridle >/dev/null; then
  echo "Starting hypridle from Ambxst environment..."
  nohup hypridle >/dev/null 2>&1 &
else
  echo "Warning: hypridle not found in PATH"
fi

# wl-clip-persist
if pgrep -x "wl-clip-persist" >/dev/null; then
  echo "Stopping existing wl-clip-persist instances..."
  pkill -x "wl-clip-persist"
  sleep 0.5
fi

if command -v wl-clip-persist >/dev/null; then
  echo "Starting wl-clip-persist from Ambxst environment..."
  nohup wl-clip-persist --clipboard regular >/dev/null 2>&1 &
else
  echo "Warning: wl-clip-persist not found in PATH"
fi
