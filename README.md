# Dark Souls II Seamless Co-op: one-command installer for Steam Deck / SteamOS

Installs [Seamless Co-op for Dark Souls II: Scholar of the First Sin](https://www.nexusmods.com/darksouls2/mods/1468)
on a Steam Deck, Steam Machine, or any Linux PC running the game through Proton.

## Install

1. Switch to **Desktop Mode** (Steam button → Power → Switch to Desktop).
2. Open **Konsole** (the terminal app).
3. Paste this and press Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/onetrickwolf/ds2-seamless-coop-installer/main/install.sh | bash
```

It will:

- find Dark Souls II (internal storage or SD card),
- download the latest Seamless Co-op release from the
  [GitHub mirror](https://github.com/yuiamoroll/DarkSouls2SeamlessCoopRelease/releases) and copy it into the game folder,
- ask for your **co-op password** (everyone you play with must use the same one),
- optionally copy your existing save so your characters show up in co-op (your original save is not changed),
- briefly close Steam to set the game's launch option so it starts with the mod, then reopen Steam.

Then launch Dark Souls II from Steam as usual. Rest at a bonfire to get the co-op items:
**Pharros' Heliograph** to host, **Fragment of Brilliance** to join.

## Update

Run the same command again. Your settings and password are kept.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/onetrickwolf/ds2-seamless-coop-installer/main/install.sh | bash -s -- --uninstall
```

This removes the mod files and launch option. Co-op saves (`.co2`) are left alone.

## Options

```
--password PW        set the co-op password without being asked
--version v0.0.5     install a specific mod version (everyone must match!)
--no-launch-option   don't touch Steam; print the launch option to paste yourself
--yes                no questions, accept defaults
```

Pass options after `bash -s --`, e.g. `... | bash -s -- --version v0.0.5`.

## Doing it by hand

If the automatic launch option step doesn't work, open Steam → Dark Souls II → Properties → General → Launch Options and paste:

```
bash -c 'exec "${@/DarkSoulsII.exe/ds2sc_launcher.exe}"' -- %command%
```

This makes Steam run the mod's `ds2sc_launcher.exe` (through Proton) instead of `DarkSoulsII.exe`.

## Notes

- The mod is **alpha** and requires game version 1.03 and being online in Steam.
- The mod is not included in this repo (its author doesn't allow redistribution); it's downloaded at install time.
- A backup of Steam's config is kept next to it as `localconfig.vdf.ds2sc-backup`.
