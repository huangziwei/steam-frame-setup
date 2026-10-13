# 01 — macOS-style keyboard

- **Date:** 2026-10-12
- **Status:** Active
- **Needs sudo:** No
- **Survives OS updates:** Yes (everything lives in the home folder)

## Why

On Linux, Ctrl does the job Cmd does on macOS. The Cmd key becomes a "Super" key used for system shortcuts. In terminals, copy and paste are Ctrl+Shift+C / Ctrl+Shift+V, because Ctrl+C has to stay "stop the running program".

The stray characters after pasting (`^[[200~ … ~`) weren't a paste bug. In bash, plain **Ctrl+V** means "insert the next keystroke literally". Pressing Ctrl+V out of Mac habit and then Ctrl+Shift+V made the hidden paste markers show up as visible text. With Cmd+V mapped straight to the terminal's paste, this no longer happens.

## What it does

[xremap](https://github.com/xremap/xremap) is a key remapper that can apply different rules depending on which app is in front. It turns both Cmd keys into *Right* Ctrl. The physical Ctrl key stays *Left* Ctrl, so the rules can still tell the two apart.

| Keys | In apps | In terminals (Konsole etc.) |
|---|---|---|
| Cmd+C / V / X / Z / A / S / T / W / Q / F / L… | same as on a Mac | copy / paste / new tab / close tab / find / select all / quit (sent as Ctrl+Shift+…) |
| Ctrl+C | — | stops the running program |
| Cmd+K | — | clear scrollback |
| Cmd+D / Cmd+Shift+D | — | split view left-right / top-bottom |
| Cmd+Z, Cmd+S, Cmd+\\ | — | do nothing (blocks accidental suspend, freeze, or quit-signal) |
| Cmd+← / → | line start / end | line start / end |
| Cmd+↑ / ↓ | top / bottom of document | — |
| Option+← / → | jump by word | jump by word |
| Option+Backspace / Cmd+Backspace | delete word / line | delete word / line |
| Cmd+[ / ] | back / forward in browsers | previous / next tab |
| Cmd+Tab | switch windows | switch windows |
| Cmd+Space | KRunner (like Spotlight) | KRunner |
| Physical Ctrl+Tab | next tab (sent as Ctrl+PageDown) | next tab |

**Trade-off:** Cmd no longer works as the Linux "Super" key, so tapping it won't open the app menu. Use Cmd+Space instead.

## Changes made

### Files created (none of these existed before)

| File | Purpose |
|---|---|
| `~/.local/bin/xremap` | xremap v0.15.14, `xremap-linux-aarch64-kde.zip` from GitHub releases. SHA-256 of the zip: `44374eec093380afab024c656ca430145450ea155153626e306fd65d6240bbee` (matches GitHub's published digest) |
| `~/.config/xremap/config.yml` | The remapping rules (commented). With `--watch=config`, edits apply as soon as you save. |
| `~/.config/systemd/user/xremap.service` | Background service that starts xremap with the Plasma desktop. It only grabs the device named "Magic Keyboard". (Widened to all keyboards in [02](02-remap-any-keyboard.md).) |
| `~/.config/systemd/user/plasma-workspace.target.wants/xremap.service` | Symlink created by `systemctl --user enable` (this is what makes it start automatically) |
| `~/.inputrc` | Includes `/etc/inputrc`, then adds Option+←/→ word jumps for bash, case-insensitive tab completion, and listing all matches on an ambiguous Tab |

### Settings modified

`~/.config/kglobalshortcutsrc`, section `[kwin]`. Added Ctrl+Tab to the window switcher, so Cmd+Tab (which arrives as Ctrl+Tab) works and the switcher stays open while Cmd is held.

| Key | Before | After |
|---|---|---|
| `Walk Through Windows` | `Alt+Tab,Alt+Tab,Walk Through Windows` | `Alt+Tab\tCtrl+Tab,Alt+Tab,Walk Through Windows` |
| `Walk Through Windows (Reverse)` | `Alt+Shift+Tab,Alt+Shift+Tab,Walk Through Windows (Reverse)` | `Alt+Shift+Tab\tCtrl+Shift+Tab,Alt+Shift+Tab,Walk Through Windows (Reverse)` |

These were also applied live, without a restart, over D-Bus (`org.kde.KGlobalAccel.setForeignShortcutKeys`).

## Everyday use

```bash
systemctl --user status xremap      # is it running?
systemctl --user restart xremap     # restart it
systemctl --user stop xremap        # turn it off for now (comes back at next login)
journalctl --user -u xremap -f      # live log; shows which app is in front, for app-specific rules
```

## How to revert

**Turn it off temporarily:** `systemctl --user stop xremap`

**Remove it completely:**

```bash
# 1. Stop and remove the remapper
systemctl --user disable --now xremap.service
rm ~/.config/systemd/user/xremap.service
systemctl --user daemon-reload
rm -r ~/.config/xremap
rm ~/.local/bin/xremap

# 2. Restore the window switcher to Alt+Tab only
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Walk Through Windows" "Alt+Tab,Alt+Tab,Walk Through Windows"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Walk Through Windows (Reverse)" "Alt+Shift+Tab,Alt+Shift+Tab,Walk Through Windows (Reverse)"
# Takes effect at the next login, or right away via:
#   System Settings → Keyboard → Shortcuts → KWin → "Walk Through Windows" → remove Ctrl+Tab

# 3. Remove the bash key bindings (falls back to /etc/inputrc)
rm ~/.inputrc
```

## Open items

- [x] Confirm the keys work with the real keyboard. Confirmed by the user on 2026-10-12.
- [x] Confirm Konsole is matched by the `/konsole/` pattern. Confirmed, since the terminal shortcuts work.
