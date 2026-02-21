# wallshift4cosmic
A simple script for automatically change wallpaper on COSMIC-DE based on time of day.
 
It reads the `schedule.json` file to determine the time intervals and corresponding wallpapers, and then sets the wallpaper accordingly by changing the `~/.config/cosmic/com.system76.CosmicBackground/v1/all` file.

The idea came from the script used by [variety](https://github.com/varietywalls/variety) wallpaper changer. 