#!/usr/bin/env bash
# Dark Souls II: Scholar of the First Sin - Seamless Co-op installer for Steam Deck / SteamOS / Linux.
#
#   curl -fsSL https://raw.githubusercontent.com/onetrickwolf/ds2-seamless-coop-installer/main/install.sh | bash
#
# Uninstall:
#   curl -fsSL https://raw.githubusercontent.com/onetrickwolf/ds2-seamless-coop-installer/main/install.sh | bash -s -- --uninstall
#
# The mod itself is NOT bundled here (the author does not allow redistribution);
# it is downloaded from the GitHub release mirror at install time.

# Everything lives inside main() so a partially-downloaded script never runs.
main() {
set -euo pipefail

APP_ID=335300
MOD_REPO="${DS2SC_REPO:-yuiamoroll/DarkSouls2SeamlessCoopRelease}"
MOD_VERSION="${DS2SC_VERSION:-latest}"

ACTION=install
ASSUME_YES=0
PASSWORD="${DS2SC_PASSWORD-}"
PASSWORD_SET=0; [ -n "${DS2SC_PASSWORD+x}" ] && PASSWORD_SET=1
SET_LAUNCH_OPTION=1

while [ $# -gt 0 ]; do
    case "$1" in
        --uninstall) ACTION=uninstall ;;
        -y|--yes) ASSUME_YES=1 ;;
        --password) PASSWORD="${2-}"; PASSWORD_SET=1; shift ;;
        --version) MOD_VERSION="${2:?--version needs a value, e.g. v0.0.5}"; shift ;;
        --no-launch-option) SET_LAUNCH_OPTION=0 ;;
        -h|--help)
            cat <<'EOF'
Usage: install.sh [--uninstall] [--yes] [--password PW] [--version vX.Y.Z] [--no-launch-option]
  --uninstall          Remove the mod files and the Steam launch option (saves are kept)
  --yes                Don't ask questions; accept defaults (closes/restarts Steam if needed)
  --password PW        Co-op session password to write to ds2sc_settings.ini
  --version TAG        Install a specific mod release instead of the latest
  --no-launch-option   Don't touch Steam's launch options (print them instead)
Env: DS2SC_GAME_DIR (override game folder), DS2SC_STEAM_ROOT, DS2SC_REPO
EOF
            return 0 ;;
        *) die "Unknown option: $1 (try --help)" ;;
    esac
    shift
done

need curl; need unzip; need python3

say "${BOLD}Dark Souls II Seamless Co-op installer${RESET}"

STEAM_ROOT="$(find_steam_root)" || die "Couldn't find your Steam folder. Is Steam installed?"
GAME_DIR="${DS2SC_GAME_DIR:-$(find_game_dir "$STEAM_ROOT")}" \
    || die "Couldn't find Dark Souls II: Scholar of the First Sin. Install it in Steam first."
[ -f "$GAME_DIR/DarkSoulsII.exe" ] || die "DarkSoulsII.exe not found in: $GAME_DIR"
ok "Found the game: $GAME_DIR"
WRAPPER="bash \"$GAME_DIR/SeamlessCoop/steam-launch.sh\""

if [ "$ACTION" = uninstall ]; then
    do_uninstall
else
    do_install
fi
}

# ---------------------------------------------------------------------------
# install / uninstall

do_install() {
    local work zip url tag
    work="$(mktemp -d)"
    # shellcheck disable=SC2064  # expand now: $work is local and gone by EXIT
    trap "rm -rf '$work'" EXIT

    say "Looking up the mod release ($MOD_VERSION)..."
    read -r tag url < <(release_asset "$MOD_REPO" "$MOD_VERSION") \
        || die "Couldn't find a download for the mod on github.com/$MOD_REPO"
    ok "Mod version: $tag"

    zip="$work/mod.zip"
    say "Downloading..."
    curl -fL --progress-bar -o "$zip" "$url" || die "Download failed."

    mkdir "$work/x"
    unzip -q "$zip" -d "$work/x" || die "The downloaded file isn't a valid zip."
    local src="$work/x"
    # Tolerate a zip that wraps everything in one top-level folder.
    if [ ! -f "$src/ds2sc_launcher.exe" ]; then
        src="$(dirname "$(find "$work/x" -name ds2sc_launcher.exe -print -quit)")"
    fi
    for f in ds2sc_launcher.exe SeamlessCoop/ds2sc.dll SeamlessCoop/ds2sc_settings.ini; do
        [ -f "$src/$f" ] || die "The download is missing $f - the release layout may have changed."
    done

    # Keep the user's existing settings across updates.
    local ini="$GAME_DIR/SeamlessCoop/ds2sc_settings.ini" old_ini=""
    if [ -f "$ini" ]; then
        old_ini="$work/old_settings.ini"
        cp "$ini" "$old_ini"
    fi

    say "Copying mod files into the game folder..."
    cp -f "$src/ds2sc_launcher.exe" "$GAME_DIR/"
    mkdir -p "$GAME_DIR/SeamlessCoop"
    cp -rf "$src/SeamlessCoop/." "$GAME_DIR/SeamlessCoop/"
    echo "$tag" > "$GAME_DIR/SeamlessCoop/.installed-version"
    write_launch_script

    if [ -n "$old_ini" ]; then
        ini_merge "$old_ini" "$ini"
        ok "Kept your previous settings."
    fi
    ok "Mod files installed."

    # Co-op password
    local current
    current="$(ini_get "$ini" cooppassword)"
    if [ "$PASSWORD_SET" = 0 ] && can_ask; then
        if [ -n "$current" ]; then
            ask "Co-op password is currently '$current'. Press Enter to keep it, or type a new one: " PASSWORD
        else
            say ""
            say "Pick a ${BOLD}co-op password${RESET}. You and your friends must all use the SAME one."
            ask "Co-op password: " PASSWORD
        fi
        [ -n "$PASSWORD" ] && PASSWORD_SET=1
    fi
    if [ "$PASSWORD_SET" = 1 ] && [ -n "$PASSWORD" ]; then
        ini_set "$ini" cooppassword "$PASSWORD"
        current="$PASSWORD"
        ok "Co-op password saved."
    fi
    [ -n "$current" ] || warn "No co-op password set - you'll need one to host or join. Edit: $ini"

    ensure_save_dir
    offer_save_copy

    if [ "$SET_LAUNCH_OPTION" = 1 ]; then
        set_launch_option add
    else
        manual_launch_option_help
    fi

    say ""
    say "${GREEN}${BOLD}All done!${RESET} Launch Dark Souls II from Steam as normal - it will start with Seamless Co-op."
    say "Rest at a bonfire in-game to receive the co-op items (Pharros' Heliograph to host,"
    say "Fragment of Brilliance to join). Everyone needs the same mod version and password."
    say "Settings file: $ini"
    say "To update later, run the same command again. To remove: add '-s -- --uninstall' after 'bash'."
}

do_uninstall() {
    say "Removing mod files..."
    rm -f "$GAME_DIR/ds2sc_launcher.exe"
    rm -rf "$GAME_DIR/SeamlessCoop"
    ok "Mod files removed (your co-op saves are kept)."
    if [ "$SET_LAUNCH_OPTION" = 1 ]; then
        set_launch_option remove
    else
        say "Remember to clear the launch option in Steam > Dark Souls II > Properties."
    fi
    say "${GREEN}${BOLD}Uninstalled.${RESET} The game will now start normally."
}

# ---------------------------------------------------------------------------
# Steam discovery

find_steam_root() {
    local c
    for c in "${DS2SC_STEAM_ROOT-}" "$HOME/.local/share/Steam" "$HOME/.steam/steam" "$HOME/.steam/root" \
             "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"; do
        if [ -n "$c" ] && [ -f "$c/steamapps/libraryfolders.vdf" ]; then
            readlink -f "$c"
            return 0
        fi
    done
    return 1
}

# Search every Steam library (internal storage, SD card, ...) for the game.
find_game_dir() {
    local lib
    while IFS= read -r lib; do
        if [ -f "$lib/steamapps/appmanifest_$APP_ID.acf" ]; then
            local dir
            dir="$(sed -n 's/^[[:space:]]*"installdir"[[:space:]]*"\(.*\)"/\1/p' "$lib/steamapps/appmanifest_$APP_ID.acf")"
            if [ -d "$lib/steamapps/common/$dir/Game" ]; then
                echo "$lib/steamapps/common/$dir/Game"
                return 0
            fi
        fi
    done < <(sed -n 's/^[[:space:]]*"path"[[:space:]]*"\(.*\)"/\1/p' "$1/steamapps/libraryfolders.vdf"; echo "$1")
    return 1
}

steam_running() { pgrep -x steam >/dev/null 2>&1; }

# Steam runs this instead of the game (via the launch option). It swaps DarkSoulsII.exe
# for the mod's launcher. In Game Mode the game, when started by the launcher, sits on a
# white screen until its window is clicked, so it also clicks the window once it appears.
write_launch_script() {
    cat > "$GAME_DIR/SeamlessCoop/steam-launch.sh" <<'SH'
#!/usr/bin/env bash
# Written by ds2-seamless-coop-installer; used by Dark Souls II's Steam launch option.
if [ "${XDG_CURRENT_DESKTOP-}" = gamescope ] && command -v xdotool >/dev/null; then
    (
        for _ in $(seq 1 120); do
            sleep 1
            win="$(xdotool search --name '^DARK SOULS II$' | head -n1)"
            if [ -n "$win" ]; then
                sleep 2
                xdotool mousemove --window "$win" 1 1 click 1
                exit 0
            fi
        done
    ) >/dev/null 2>&1 </dev/null &
fi
exec "${@/DarkSoulsII.exe/ds2sc_launcher.exe}"
SH
    chmod +x "$GAME_DIR/SeamlessCoop/steam-launch.sh"
}

# ---------------------------------------------------------------------------
# Launch option (stored in userdata/<id>/config/localconfig.vdf; Steam must be
# closed while we edit it or it will overwrite our change on exit).

set_launch_option() {
    local mode="$1" restart=0
    if steam_running; then
        if is_gamescope; then
            warn "Steam is running in Game Mode, so the launch option can't be set automatically."
            manual_launch_option_help "$mode"
            return 0
        fi
        say ""
        say "To change Dark Souls II's launch option, Steam needs to close for a moment (it will reopen)."
        if ! confirm "Close Steam now?"; then
            manual_launch_option_help "$mode"
            return 0
        fi
        say "Closing Steam..."
        steam -shutdown >/dev/null 2>&1 </dev/null || "$STEAM_ROOT/steam.sh" -shutdown >/dev/null 2>&1 </dev/null || true
        local i
        for i in $(seq 1 60); do steam_running || break; sleep 1; done
        if steam_running; then
            warn "Steam didn't close in time."
            manual_launch_option_help "$mode"
            return 0
        fi
        restart=1
    fi

    local f changed=0
    for f in "$STEAM_ROOT"/userdata/*/config/localconfig.vdf; do
        [ -f "$f" ] || continue
        cp "$f" "$f.ds2sc-backup"
        if python3 -I - "$f" "$APP_ID" "$mode" "$WRAPPER" <<'PY'
import sys

import re

path, app_id, mode, wrapper = sys.argv[1:5]

def tokenize(text):
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c.isspace():
            i += 1
        elif text.startswith("//", i):
            while i < n and text[i] != "\n":
                i += 1
        elif c in "{}":
            yield c; i += 1
        elif c == '"':
            i += 1; buf = []
            while i < n and text[i] != '"':
                if text[i] == "\\" and i + 1 < n:
                    buf.append({"n": "\n", "t": "\t", "\\": "\\", '"': '"'}.get(text[i + 1], "\\" + text[i + 1])); i += 2
                else:
                    buf.append(text[i]); i += 1
            i += 1
            yield ("s", "".join(buf))
        else:
            j = i
            while j < n and not text[j].isspace() and text[j] not in '{}"':
                j += 1
            yield ("s", text[i:j]); i = j

def parse(tokens):
    out = []  # list of [key, value] keeps order and duplicates
    for tok in tokens:
        if tok == "}":
            return out
        key = tok[1]
        nxt = next(tokens)
        out.append([key, parse(tokens) if nxt == "{" else nxt[1]])
    return out

def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')

def dump(node, depth=0):
    tabs = "\t" * depth; lines = []
    for k, v in node:
        if isinstance(v, list):
            lines.append(f'{tabs}"{esc(k)}"\n{tabs}{{\n{dump(v, depth + 1)}{tabs}}}\n')
        else:
            lines.append(f'{tabs}"{esc(k)}"\t\t"{esc(v)}"\n')
    return "".join(lines)

def child(node, key, create):
    for kv in node:
        if kv[0].lower() == key.lower() and isinstance(kv[1], list):
            return kv[1]
    if not create:
        return None
    new = []; node.append([key, new]); return new

with open(path, encoding="utf-8") as fh:
    original = fh.read()
root = parse(tokenize(original))

node = child(root, "UserLocalConfigStore", mode == "add")
for key in ("Software", "Valve", "Steam", "apps", app_id):
    if node is None:
        break
    node = child(node, key, mode == "add")
if node is None:
    sys.exit(3)  # nothing to remove

entry = next((kv for kv in node if kv[0] == "LaunchOptions"), None)
current = entry[1] if entry else ""

# Any wrapper this installer has ever written (older versions used an inline bash -c).
ours = re.compile(r"""bash -c 'exec "\$\{@/DarkSoulsII\.exe/ds2sc_launcher\.exe\}"' -- ?"""
                  r"""|bash "[^"]*/SeamlessCoop/steam-launch\.sh" ?""")
base = ours.sub("", current).strip()
if base == "%command%":
    base = ""

if mode == "add":
    if "%command%" in base:
        new = base.replace("%command%", wrapper + " %command%", 1)
    elif base:
        new = f"{wrapper} %command% {base}"
    else:
        new = f"{wrapper} %command%"
else:
    new = base
if new == current:
    sys.exit(3)

if entry:
    entry[1] = new
else:
    node.append(["LaunchOptions", new])

tmp = path + ".tmp"
with open(tmp, "w", encoding="utf-8") as fh:
    fh.write(dump(root))
import os
os.replace(tmp, path)
PY
        then
            changed=1
        else
            local rc=$?
            rm -f "$f.ds2sc-backup"
            [ "$rc" = 3 ] || warn "Couldn't update $f (error $rc)."
        fi
    done

    if [ "$changed" = 1 ]; then
        if [ "$mode" = add ]; then ok "Steam launch option set."; else ok "Steam launch option removed."; fi
    elif [ "$mode" = add ]; then
        ok "Steam launch option was already set."
    fi

    if [ "$restart" = 1 ]; then
        say "Reopening Steam..."
        restart_steam
        local i
        for i in $(seq 1 30); do steam_running && break; sleep 1; done
        steam_running || warn "Steam didn't reopen by itself - please start it from the desktop."
    fi
}

restart_steam() {
    # If run from somewhere without the desktop's display variables (ssh, a service, ...),
    # point Steam at the local desktop session so it can open its window.
    local rt="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" xa
    if [ -z "${DISPLAY-}" ] && [ -z "${WAYLAND_DISPLAY-}" ]; then
        [ -S /tmp/.X11-unix/X0 ] && export DISPLAY=:0
        [ -S "$rt/wayland-0" ] && export WAYLAND_DISPLAY=wayland-0
        if [ -z "${XAUTHORITY-}" ]; then
            xa="$(find "$rt" -maxdepth 1 -name 'xauth_*' -print -quit 2>/dev/null)"
            [ -n "$xa" ] && export XAUTHORITY="$xa"
        fi
        export XDG_RUNTIME_DIR="$rt"
    fi
    (setsid steam >/dev/null 2>&1 </dev/null &)
}

manual_launch_option_help() {
    if [ "${1:-add}" = remove ]; then
        say "In Steam: Dark Souls II > Properties > General > Launch Options, delete the text that's there."
        return
    fi
    say ""
    say "${BOLD}One manual step:${RESET} in Steam, right-click Dark Souls II > Properties > General,"
    say "and paste this into ${BOLD}Launch Options${RESET}:"
    say ""
    say "    $WRAPPER %command%"
    say ""
}

is_gamescope() { [ "${XDG_CURRENT_DESKTOP-}" = gamescope ] || pgrep -x gamescope-wl >/dev/null 2>&1 && ! pgrep -x plasmashell >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# Saves live in the game's Proton prefix (compatdata), normally in the same library as the game.

steamuser_dir() {
    local c
    for c in "$(readlink -f "$GAME_DIR/../../..")/compatdata/$APP_ID" "$STEAM_ROOT/steamapps/compatdata/$APP_ID"; do
        if [ -d "$c/pfx/drive_c/users/steamuser" ]; then
            echo "$c/pfx/drive_c/users/steamuser"
            return 0
        fi
    done
    return 1
}

# The mod crashes on startup (std::filesystem error) if the game's save folder
# doesn't exist yet, which is the case until the unmodded game has run once.
ensure_save_dir() {
    local user id
    if ! user="$(steamuser_dir)"; then
        warn "Dark Souls II hasn't been started on this machine yet."
        warn "Launch it once from Steam (it may close straight away), then run this installer again."
        return 0
    fi
    for id in "$STEAM_ROOT"/userdata/*/; do
        id="$(basename "$id")"
        case "$id" in ''|0|*[!0-9]*) continue ;; esac
        mkdir -p "$user/AppData/Roaming/DarkSoulsII/$(printf '%016x' $((0x0110000100000000 + id)))"
    done
}

# ---------------------------------------------------------------------------
# Optional: start co-op with a copy of the existing vanilla save.

offer_save_copy() {
    local user base
    user="$(steamuser_dir)" || return 0
    base="$user/AppData/Roaming/DarkSoulsII"
    [ -d "$base" ] || return 0

    local ext sl2 co2
    ext="$(ini_get "$GAME_DIR/SeamlessCoop/ds2sc_settings.ini" save_file_extension)"; ext="${ext:-co2}"
    while IFS= read -r sl2; do
        co2="${sl2%.sl2}.$ext"
        [ -e "$co2" ] && continue
        can_ask || continue
        say ""
        say "You have an existing (non-modded) save: $(basename "$sl2")"
        if confirm "Copy it so your characters are available in Seamless Co-op? (your original is not touched)" n; then
            cp "$sl2" "$co2"
            ok "Copied save to $(basename "$co2")."
        fi
    done < <(find "$base" -name '*.sl2' 2>/dev/null)
}

# ---------------------------------------------------------------------------
# GitHub release lookup -> prints "<tag> <zip url>"

release_asset() {
    local repo="$1" version="$2" api
    if [ "$version" = latest ]; then
        api="https://api.github.com/repos/$repo/releases/latest"
    else
        api="https://api.github.com/repos/$repo/releases/tags/$version"
    fi
    curl -fsSL -H "Accept: application/vnd.github+json" "$api" | python3 -I -c '
import json, sys
r = json.load(sys.stdin)
zips = [a["browser_download_url"] for a in r.get("assets", []) if a["name"].lower().endswith(".zip")]
if not zips:
    sys.exit(1)
print(r["tag_name"], zips[0])
'
}

# ---------------------------------------------------------------------------
# ini helpers (simple "key = value" lines)

ini_get() {
    [ -f "$1" ] || return 0
    sed -n "s/^[[:space:]]*$2[[:space:]]*=[[:space:]]*\(.*\)$/\1/p" "$1" | head -n1 | tr -d '\r' | sed 's/[[:space:]]*$//'
}

ini_set() {
    python3 -I - "$1" "$2" "$3" <<'PY'
import re, sys
path, key, value = sys.argv[1:4]
with open(path, encoding="utf-8", newline="") as fh:
    lines = fh.readlines()
pat = re.compile(r"^(\s*" + re.escape(key) + r"\s*=)(.*?)(\r?\n?)$")
for i, line in enumerate(lines):
    m = pat.match(line)
    if m:
        lines[i] = f"{m.group(1)} {value}{m.group(3)}"
        break
with open(path, "w", encoding="utf-8", newline="") as fh:
    fh.writelines(lines)
PY
}

# Copy values from the old ini into the new one for every key both files have.
ini_merge() {
    local key val
    while IFS='=' read -r key val; do
        key="$(echo "$key" | tr -d '[:space:]')"
        case "$key" in ''|\;*|\[*) continue ;; esac
        val="$(ini_get "$1" "$key")"
        if grep -qE "^[[:space:]]*$key[[:space:]]*=" "$2"; then
            ini_set "$2" "$key" "$val"
        fi
    done < "$1"
}

# ---------------------------------------------------------------------------
# UI helpers. When piped from curl, stdin is the script, so questions read /dev/tty.

if [ -t 1 ]; then BOLD=$'\e[1m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; RESET=$'\e[0m'
else BOLD=""; GREEN=""; YELLOW=""; RED=""; RESET=""; fi

say()  { printf '%s\n' "$*"; }
ok()   { printf '%s\n' "${GREEN}✔${RESET} $*"; }
warn() { printf '%s\n' "${YELLOW}!${RESET} $*" >&2; }
die()  { printf '%s\n' "${RED}✘ $*${RESET}" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing required program: $1"; }

can_ask() { [ "$ASSUME_YES" = 0 ] && { : </dev/tty; } 2>/dev/null; }

ask() {  # ask "prompt" VAR
    local reply=""
    if can_ask; then
        printf '%s' "$1" >/dev/tty
        IFS= read -r reply </dev/tty || true
    fi
    printf -v "$2" '%s' "$reply"
}

confirm() {  # confirm "question" [default y|n]
    local def="${2:-y}" reply
    if ! can_ask; then [ "$def" = y ]; return; fi
    if [ "$def" = y ]; then ask "$1 [Y/n] " reply; else ask "$1 [y/N] " reply; fi
    reply="${reply:-$def}"
    [[ "$reply" =~ ^[Yy] ]]
}

main "$@"
