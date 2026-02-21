#!/usr/bin/env bash

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/wallpaper-schedule/schedule.json"

if [ ! -f "$CONFIG" ]; then
    echo "Config file not found: $CONFIG" >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "jq is required but not installed." >&2
    exit 1
fi

# Current time as minutes since midnight
NOW_MIN=$(( 10#$(date +%H) * 60 + 10#$(date +%M) ))

# Find the first wallpaper entry whose time range covers now.
# Ranges crossing midnight (e.g. 21:00–06:00) are handled correctly.
WALLPAPER=$(jq -r --argjson now "$NOW_MIN" '
  .wallpapers[] |
  (.start | split(":") | (.[0] | tonumber) * 60 + (.[1] | tonumber)) as $start |
  (.end   | split(":") | (.[0] | tonumber) * 60 + (.[1] | tonumber)) as $end |
  if $start < $end then
    select($now >= $start and $now < $end)
  else
    select($now >= $start or  $now < $end)
  end |
  .path
' "$CONFIG" | head -1)

if [ -z "$WALLPAPER" ]; then
    echo "No wallpaper entry matches the current time." >&2
    exit 1
fi

sed -r --in-place 's,source: Path\(".*"\),source: Path("'"$WALLPAPER"'"),gm' \
    ~/.config/cosmic/com.system76.CosmicBackground/v1/all
