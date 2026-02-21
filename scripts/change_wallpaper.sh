#!/usr/bin/env bash

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/wallpaper-schedule/schedule.json"
COSMIC_CONFIG="$HOME/.config/cosmic/com.system76.CosmicBackground/v1/all"

if [ ! -f "$CONFIG" ]; then
    echo "Config file not found: $CONFIG" >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "jq is required but not installed." >&2
    exit 1
fi

# Current time as minutes since midnight (single date call to avoid race condition)
NOW=$(date +%H:%M)
NOW_MIN=$(( 10#${NOW%%:*} * 60 + 10#${NOW##*:} ))

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

# Fallback: no range matched — pick the entry with the most recent start time
if [ -z "$WALLPAPER" ]; then
    WALLPAPER=$(jq -r --argjson now "$NOW_MIN" '
      .wallpapers |
      map(
        (.start | split(":") | (.[0] | tonumber) * 60 + (.[1] | tonumber)) as $start |
        { path: .path, diff: (($now - $start + 1440) % 1440) }
      ) |
      sort_by(.diff) |
      first.path
    ' "$CONFIG")
    echo "Warning: no schedule entry covers the current time, falling back to most recent entry." >&2
fi

if [ -z "$WALLPAPER" ]; then
    echo "No wallpaper entry found in schedule." >&2
    exit 1
fi

if ! grep -q 'source: Path(' "$COSMIC_CONFIG"; then
    echo "Unexpected format in COSMIC config — pattern 'source: Path(...)' not found." >&2
    exit 1
fi

ESCAPED=$(printf '%s\n' "$WALLPAPER" | sed 's/[&\\/]/\\&/g')
sed --in-place "s|source: Path(\".*\")|source: Path(\"$ESCAPED\")|gm" ${COSMIC_CONFIG}