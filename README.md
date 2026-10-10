# DS2 Seamless Co-op installer for Steam Deck

Installs [Seamless Co-op](https://www.nexusmods.com/darksouls2/mods/1468) for Dark Souls II: Scholar of the First Sin on Steam Deck / SteamOS.

## Install

In Desktop Mode, open Konsole and run:

```bash
curl -fsSL https://raw.githubusercontent.com/onetrickwolf/ds2-seamless-coop-installer/main/install.sh | bash
```

It downloads the latest release, asks for your co-op password, and sets the Steam launch option (Steam restarts briefly). Run it again to update.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/onetrickwolf/ds2-seamless-coop-installer/main/install.sh | bash -s -- --uninstall
```

Co-op saves are kept.

## Manual launch option

If setting it automatically fails, paste this into Steam → Properties → Launch Options:

```
bash -c 'exec "${@/DarkSoulsII.exe/ds2sc_launcher.exe}"' -- %command%
```

Run `install.sh --help` for other options.
