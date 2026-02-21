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
cp scripts/change_wallpaper.sh scripts/generate_timer.sh ~/.local/bin/
chmod +x ~/.local/bin/change_wallpaper.sh ~/.local/bin/generate_timer.sh
```

Or, if you prefer fish shell:

```bash
cp scripts/change_wallpaper.fish scripts/generate_timer.fish ~/.local/bin/
chmod +x ~/.local/bin/change_wallpaper.fish ~/.local/bin/generate_timer.fish
```

### 2. Set up the schedule

```bash
mkdir -p ~/.config/wallpaper-schedule
cp schedule.json ~/.config/wallpaper-schedule/
```

Edit `~/.config/wallpaper-schedule/schedule.json` to set your desired time ranges and wallpaper paths. Make sure to replace the placeholder `/path/to/*.jpg` values with absolute paths to your actual wallpaper files.

### 3. Install the systemd units

```bash
mkdir -p ~/.config/systemd/user
cp systemd/change-wallpaper.service \
   systemd/generate-wallpaper-timer.service \
   systemd/generate-wallpaper-timer.path \
   ~/.config/systemd/user/
```

> **Note:** do not copy `systemd/change-wallpaper.timer` — it is generated from your schedule in the next step. It is included in the repository for reference only.

### 4. Generate the timer and enable everything

```bash
bash ~/.local/bin/generate_timer.sh
systemctl --user daemon-reload
systemctl --user enable --now change-wallpaper.timer
systemctl --user enable --now generate-wallpaper-timer.path
```

`generate_timer.sh` writes `~/.config/systemd/user/change-wallpaper.timer` with an `OnCalendar` entry for every `start` time in your schedule, then reloads and restarts the timer automatically.

### 5. Apply the wallpaper immediately

```bash
bash ~/.local/bin/change_wallpaper.sh
```

## Usage

- **Update the schedule**: edit `~/.config/wallpaper-schedule/schedule.json` and save — the path watcher (`generate-wallpaper-timer.path`) will detect the change and regenerate the timer automatically.

- **Check timer status**:
  ```bash
  systemctl --user status change-wallpaper.timer
  systemctl --user list-timers change-wallpaper.timer
  ```
