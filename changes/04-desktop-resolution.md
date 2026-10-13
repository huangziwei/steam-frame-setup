# 04 — Full-width desktop (remove the black side bars)

- **Date:** 2026-10-12
- **Status:** Active. Verified 2026-10-12 after a desktop restart.
- **Needs sudo:** No
- **Survives OS updates:** Yes (user-level systemd override in the home folder)

## Why

On the Steam Frame, desktop mode isn't drawn on a physical screen. The layers are:

```
SteamVR  →  gamescope (Steam's compositor; shows the desktop as a big virtual screen in VR)
              └─ gives the desktop a 1920×1080 (16:9) frame: --nested-width 1920 --nested-height 1080
                   └─ KWin (KDE's window manager), running *as a window* inside gamescope
                        └─ your Plasma desktop and apps
```

SteamOS starts KWin with no size (`kwin_wayland_wrapper --xwayland`), so KWin uses its built-in default for this nested mode: **1024×768**, which is 4:3. Gamescope fits that 4:3 picture into its 16:9 frame and fills the leftover space with black bars on the left and right.

What we found (2026-10-12):

| | Value |
|---|---|
| `kscreen-doctor -o` | output `X11-0`, only mode `1024x768@60`, scale 1 |
| gamescope args | `--nested-width 1920 --nested-height 1080 --output-width 1920 --output-height 1080` |
| `kwin_wayland --help` | "--width … Default width is 1024", "--height … Default height is 768" |

The Display settings page can't fix this, because 1024×768 is the only mode KWin offers there. The size has to be set when KWin starts.

## Changes made

### File created

`~/.config/systemd/user/plasma-kwin_wayland.service.d/desktop-resolution.conf`

This is a systemd override ("drop-in") that replaces the KWin start command for this user only:

| | Command |
|---|---|
| Before (Valve's default, still in `/usr/lib/systemd/user/plasma-kwin_wayland.service`) | `/usr/bin/kwin_wayland_wrapper --xwayland` |
| After | `/usr/bin/kwin_wayland_wrapper --xwayland --width 1920 --height 1080` |

Tested beforehand on a separate, invisible KWin instance with its own private message bus (`dbus-run-session -- kwin_wayland --virtual --width 1920 --height 1080`). It started cleanly.

### Backup

[`backups/04/kwinoutputconfig.json.before`](../backups/04/kwinoutputconfig.json.before) is the display config before the change, with mode 1024×768 at scale 1. KWin may rewrite this file to the new 1920×1080 mode after the restart.

## How to apply

1. Save your work. Restarting desktop mode closes every app, **including Konsole and this Claude Code session**.
2. Restart desktop mode: switch to Game Mode and back to Desktop, or log out, or reboot.
3. To pick this conversation back up afterwards, open Konsole and run:
   ```bash
   cd ~/Works/Frame && claude --continue
   ```

## What to expect

- The desktop fills the whole virtual screen, with no side bars.
- **Sharper text.** Gamescope no longer stretches a 1024×768 image up to 1080 lines; the desktop is drawn at the virtual screen's native size.
- **Everything looks about 30% smaller** than before, for the same reason. In exchange you get much more room (1920 wide instead of 1024). If it's too small, go to **System Settings → Display & Monitor → Scale** and try **125%** or **150%**. Valve's own reference scale for SteamVR is 1.5×. At 150% you'd have roughly the old size, but sharp and wider.

## Caveat

The override replaces the whole start command. If a future SteamOS update changes how Valve starts KWin (for example, by adding new options), this override would hide that change. If desktop mode misbehaves after an update, check `systemctl --user cat plasma-kwin_wayland.service` and compare the two `ExecStart` lines.

## How to revert

```bash
rm -r ~/.config/systemd/user/plasma-kwin_wayland.service.d
systemctl --user daemon-reload
# Optional: restore the previous display config
cp ~/Works/Frame/backups/04/kwinoutputconfig.json.before ~/.config/kwinoutputconfig.json
```

Then restart desktop mode.

## Open items

- [x] After restarting desktop mode: confirm the black bars are gone. The user confirmed it worked. `kscreen-doctor -o` shows mode `1920x1080@60`, geometry `1920x1080`, and the running `kwin_wayland` has `--width 1920 --height 1080`.
- [x] Scale: left at **100%**; the user hasn't changed it. To change it later: System Settings → Display & Monitor → Scale.

## Result (2026-10-12)

| | Before | After |
|---|---|---|
| Desktop resolution | 1024×768 (4:3) | 1920×1080 (16:9) |
| Black side bars | yes | no |
| Scale | 100% | 100% |
| Usable width | 1024 px | 1920 px |

The xremap keyboard service (changes [01](01-macos-keyboard.md)/[02](02-remap-any-keyboard.md)) restarted automatically with the new desktop session, as intended.
