#!/usr/bin/env fish

if set -q XDG_CONFIG_HOME
    set config_base $XDG_CONFIG_HOME
else
    set config_base $HOME/.config
end

set CONFIG $config_base/wallpaper-schedule/schedule.json
set TIMER_FILE $config_base/systemd/user/change-wallpaper.timer

if not test -f $CONFIG
    echo "Config file not found: $CONFIG" >&2
    exit 1
end

if not type -q jq
    echo "jq is required but not installed." >&2
    exit 1
end

# Extract all unique start times from the schedule, sorted
set STARTS (jq -r '[.wallpapers[].start] | unique | .[]' $CONFIG)

if test (count $STARTS) -eq 0
    echo "No start times found in schedule." >&2
    exit 1
end

# Validate and build OnCalendar lines
set ON_CALENDAR_LINES
for time in $STARTS
    if not string match -qr '^([01][0-9]|2[0-3]):[0-5][0-9]$' $time
        echo "Invalid time format in schedule: '$time'" >&2
        exit 1
    end
    set -a ON_CALENDAR_LINES "OnCalendar=*-*-* $time:00"
end

# Warn if the schedule does not cover the full 24 hours
set COVERAGE (jq '
  [.wallpapers[] |
    (.start | split(":") | (.[0] | tonumber) * 60 + (.[1] | tonumber)) as $start |
    (.end   | split(":") | (.[0] | tonumber) * 60 + (.[1] | tonumber)) as $end |
    if $end > $start then $end - $start else 1440 - $start + $end end
  ] | add
' $CONFIG)

if test $COVERAGE -ne 1440
    echo "Warning: schedule covers $COVERAGE/1440 minutes — some times have no matching entry and will fall back to the most recent one." >&2
end

# Write the timer file
mkdir -p (dirname $TIMER_FILE)

begin
    echo '[Unit]'
    echo 'Description=Trigger wallpaper change at day/night boundaries'
    echo ''
    echo '[Timer]'
    for line in $ON_CALENDAR_LINES
        echo $line
    end
    echo 'Persistent=true'
    echo ''
    echo '[Install]'
    echo 'WantedBy=timers.target'
end > $TIMER_FILE

echo "Timer written to $TIMER_FILE"
echo 'Active OnCalendar entries:'
grep OnCalendar $TIMER_FILE

# Reload systemd and restart the timer if it's already enabled
if systemctl --user is-enabled --quiet change-wallpaper.timer 2>/dev/null
    systemctl --user daemon-reload
    systemctl --user restart change-wallpaper.timer
    echo 'Timer reloaded and restarted.'
else
    echo 'Run the following to enable the timer:'
    echo '  systemctl --user daemon-reload'
    echo '  systemctl --user enable --now change-wallpaper.timer'
end
