# DS2 Seamless Co-op installer for Steam Deck

Installs [Seamless Co-op](https://www.nexusmods.com/darksouls2/mods/1468) for Dark Souls II: Scholar of the First Sin on Steam Deck / SteamOS.

## Install

In Desktop Mode, open Konsole and run:

```bash
curl -fsSL https://ds2.otw.gg | bash
```

It downloads the latest release, asks for your co-op password, and sets the Steam launch option (Steam restarts briefly). Run it again to update.

`ds2.otw.gg` is just a short address that serves `install.sh` from this repo.

Everyone playing together needs the same password. To set it without being asked:

```bash
curl -fsSL https://ds2.otw.gg | bash -s -- --password yourpassword
```

## Uninstall

```bash
curl -fsSL https://ds2.otw.gg | bash -s -- --uninstall
```

Co-op saves are kept.

## Manual launch option

If setting it automatically fails, the installer prints the line to paste into Steam → Properties → Launch Options. For the default install location it's:

```
bash "/home/deck/.local/share/Steam/steamapps/common/Dark Souls II Scholar of the First Sin/Game/SeamlessCoop/steam-launch.sh" %command%
```

In Game Mode this also nudges the mouse by a pixel at startup until the game is running; without it the game sits on a white screen until the mouse moves.

Run `install.sh --help` for other options.
