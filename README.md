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

## What it does

- Downloads the latest release zip from the mod author's GitHub release page, [yuiamoroll/DarkSouls2SeamlessCoopRelease](https://github.com/yuiamoroll/DarkSouls2SeamlessCoopRelease). The mod itself isn't bundled here.
- Copies `ds2sc_launcher.exe` and the `SeamlessCoop` folder into the game folder. If you're updating, your existing settings are kept.
- Writes `SeamlessCoop/steam-launch.sh` next to them and sets the game's Steam launch option to run it. Steam has to be closed for that, so it asks first and reopens Steam afterwards. The config file it edits is backed up beside itself as `localconfig.vdf.ds2sc-backup`.
- Offers to copy your existing save so your characters are available in co-op. The mod keeps its own save file (`.co2`), so your normal save is never touched.

It never needs root and doesn't touch anything outside your Steam folders. `--uninstall` removes the mod files and the launch option; co-op saves and the config backup are left alone.

Prefer to read it before running it?

```bash
curl -fsSL https://raw.githubusercontent.com/onetrickwolf/ds2-seamless-coop-installer/main/install.sh -o install.sh
less install.sh
bash install.sh
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
