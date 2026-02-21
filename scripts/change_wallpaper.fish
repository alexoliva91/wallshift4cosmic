#!/usr/bin/env fish

set CONFIG (test -n "$XDG_CONFIG_HOME" && echo "$XDG_CONFIG_HOME" || echo "$HOME/.config")/wallpaper-schedule/schedule.json
set COSMIC_CONFIG "$HOME/.config/cosmic/com.system76.CosmicBackground/v1/all"

echo $CONFIG
echo $COSMIC_CONFIG

if not test -f "$CONFIG"
    echo "Config file not found: $CONFIG" >&2
    exit 1
end

if not command -v jq &>/dev/null
    echo "jq is required but not installed." >&2
    exit 1
end

# Current time as minutes since midnight
set NOW (date +%H:%M)
set NOW_H (string split ":" $NOW)[1]
set NOW_M (string split ":" $NOW)[2]
set NOW_MIN (math "$NOW_H * 60 + $NOW_M")

# Find the first wallpaper entry whose time range covers now
set WALLPAPER (jq -r --argjson now "$NOW_MIN" '
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
if test -z "$WALLPAPER"
    set WALLPAPER (jq -r --argjson now "$NOW_MIN" '
      .wallpapers |
      map(
        (.start | split(":") | (.[0] | tonumber) * 60 + (.[1] | tonumber)) as $start |
        { path: .path, diff: (($now - $start + 1440) % 1440) }
      ) |
      sort_by(.diff) |
      first.path
    ' "$CONFIG")
    echo "Warning: no schedule entry covers the current time, falling back to most recent entry." >&2
end

if test -z "$WALLPAPER"
    echo "No wallpaper entry found in schedule." >&2
    exit 1
end

if not grep -q 'source: Path(' "$COSMIC_CONFIG"
    echo "Unexpected format in COSMIC config — pattern 'source: Path(...)' not found." >&2
    exit 1
end

echo $WALLPAPER
sed -i "s|source: Path(\".*\")|source: Path(\"$WALLPAPER\")|" $COSMIC_CONFIG