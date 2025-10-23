# moro_race

This is a redm standalone script for race events.
Setup race start coords, checkpoints (the last one is the finish line) and "fireworks" explosions at the finish line.  

## Installation
Place the folder in your resources folder.
Add `ensure moro_race` to your server.cfg.
Restart your server or just start the resource. (which is restartable live)

## Configuration
Open `config.lua` and adjust values.
Use `/addCp` command to add checkpoints in game (you need to be in devMode).  
Use `/addArrow f|b` command to add arrows in front of your character position, **forward** or **backward**.

### Each command copy the coords to your clipboard, so you can paste them in the config file directly. But use `/addCp` before `/addArrow f|b` to it, because the arrows are deleted when the next checkpoint is passed.

Example: `/addArrow f`
You can restart the resource live, mount dispawn and fx effects will be removed on stop.

If you set Config.fireOnFinish to true, fireworks will be triggered at the finish line.
You can also set the offset of the fireworks in Config.fireOffset.

Timeout handling is also available, set Config.raceTimeout to the desired time in seconds. If a player doesn't finish the race, the mount will dispawn to avoid players using free mounts for too long.

If you set Config.bringOwnMount to true, players will use their own mounts instead of spawning a new one.
If you set it to false you will need to configure the mount model in Config.mountType.

A player limit is also available, set Config.playerLimit to the desired number of players allowed in the race to avoid overcrowding.


### Disclaimer
*You have to use your own mapping (because every race is different in your imagination. I don't want to limit you, but yes it's more configuration I tried to make it easy).
for race props look for "race" and "finish" in spooner objects*

**This script was tested on a vorp server, in multiplayer with other players, but it may require adjustments to work properly in your specific server environment. Don't hesitate to open an issue if you find bugs or need help. It might be possible I forgot something, I'm not (totally) a robot!**  

*beep/boop*

### Credits

- Created by Morojgovany.
- Thanks to @klandestino7 for https://github.com/Faroeste-Roleplay/RedM-ParticleViewer which helped me a lot to find the right particle effects for the checkpoints and arrows.
