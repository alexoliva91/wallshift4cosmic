#!/usr/bin/env bash

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/wallpaper-schedule/schedule.json"
TIMER_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/change-wallpaper.timer"

if [ ! -f "$CONFIG" ]; then
    echo "Config file not found: $CONFIG" >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "jq is required but not installed." >&2
    exit 1
fi

# Extract all unique start times from the schedule, sorted
STARTS=$(jq -r '[.wallpapers[].start] | unique | .[]' "$CONFIG")

if [ -z "$STARTS" ]; then
    echo "No start times found in schedule." >&2
    exit 1
fi

# OnCalendar lines
ON_CALENDAR_LINES=""
while IFS= read -r time; do
    ON_CALENDAR_LINES+="OnCalendar=*-*-* ${time}:00"$'\n'
done <<< "$STARTS"

# write the timer file
mkdir -p "$(dirname "$TIMER_FILE")"

cat > "$TIMER_FILE" <<EOF
[Unit]
Description=Trigger wallpaper change at day/night boundaries

[Timer]
${ON_CALENDAR_LINES}Persistent=true

[Install]
WantedBy=timers.target
EOF

echo "Timer written to $TIMER_FILE"
echo "Active OnCalendar entries:"
grep OnCalendar "$TIMER_FILE"

# Reload systemd and restart the timer if it's already enabled
if systemctl --user is-enabled --quiet change-wallpaper.timer 2>/dev/null; then
    systemctl --user daemon-reload
    systemctl --user restart change-wallpaper.timer
    echo "Timer reloaded and restarted."
else
    echo "Run the following to enable the timer:"
    echo "  systemctl --user daemon-reload"
    echo "  systemctl --user enable --now change-wallpaper.timer"
fi
