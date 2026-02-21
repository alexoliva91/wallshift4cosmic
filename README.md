# wallshift4cosmic
A simple script for automatically change wallpaper on COSMIC-DE based on time of day.
 
It reads the `schedule.json` file to determine the time intervals and corresponding wallpapers, and then sets the wallpaper accordingly by changing the `~/.config/cosmic/com.system76.CosmicBackground/v1/all` file.

The idea came from the script used by [variety](https://github.com/varietywalls/variety) wallpaper changer. 

## Requirements

- [`jq`](https://stedolan.github.io/jq/) — used to parse `schedule.json`
- A COSMIC DE session

## Installation

### 1. Install the scripts

```bash
mkdir -p ~/.local/bin
cp change_wallpaper.sh generate_timer.sh ~/.local/bin/
chmod +x ~/.local/bin/change_wallpaper.sh ~/.local/bin/generate_timer.sh
```

### 2. Set up the schedule

```bash
mkdir -p ~/.config/wallpaper-schedule
cp schedule.json ~/.config/wallpaper-schedule/
```

Edit `~/.config/wallpaper-schedule/schedule.json` to set your desired time ranges and wallpaper paths.

### 3. Install the systemd units

```bash
mkdir -p ~/.config/systemd/user
cp change-wallpaper.service \
   change-wallpaper.timer \
   generate-wallpaper-timer.service \
   generate-wallpaper-timer.path \
   ~/.config/systemd/user/
```

### 4. Generate the timer and enable everything

```bash
bash ~/.local/bin/generate_timer.sh
systemctl --user daemon-reload
systemctl --user enable --now change-wallpaper.timer
systemctl --user enable --now generate-wallpaper-timer.path
```

`generate_timer.sh` writes `~/.config/systemd/user/change-wallpaper.timer` with an `OnCalendar` entry for every `start` time in your schedule, then reloads the timer automatically.

## Usage

- **Apply the wallpaper immediately** for the current time:

  ```bash
  bash ~/.local/bin/change_wallpaper.sh
  ```

- **Update the schedule**: edit `~/.config/wallpaper-schedule/schedule.json` and save — the path watcher (`generate-wallpaper-timer.path`) will detect the change and regenerate the timer automatically.

- **Check timer status**:
  ```bash
  systemctl --user status change-wallpaper.timer
  systemctl --user list-timers change-wallpaper.timer
  ```
