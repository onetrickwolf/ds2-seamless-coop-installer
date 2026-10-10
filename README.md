# DS2 Seamless Co-op installer for Steam Deck

Installs [Seamless Co-op](https://www.nexusmods.com/darksouls2/mods/1468) for Dark Souls II: Scholar of the First Sin on Steam Deck / SteamOS.

## Install

In Desktop Mode, open Konsole and run:

```bash
curl -fsSL https://raw.githubusercontent.com/onetrickwolf/ds2-seamless-coop-installer/main/install.sh | bash
```

It downloads the latest release, asks for your co-op password, and sets the Steam launch option (Steam restarts briefly). Run it again to update.

Everyone playing together needs the same password. To set it without being asked:

```bash
curl -fsSL https://raw.githubusercontent.com/onetrickwolf/ds2-seamless-coop-installer/main/install.sh | bash -s -- --password yourpassword
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/onetrickwolf/ds2-seamless-coop-installer/main/install.sh | bash -s -- --uninstall
```

Co-op saves are kept.

## Manual launch option

If setting it automatically fails, the installer prints the line to paste into Steam → Properties → Launch Options. For the default install location it's:

```
bash "/home/deck/.local/share/Steam/steamapps/common/Dark Souls II Scholar of the First Sin/Game/SeamlessCoop/steam-launch.sh" %command%
```

In Game Mode this also clicks the game window once at startup; without it the game sits on a white screen until clicked.

Run `install.sh --help` for other options.
