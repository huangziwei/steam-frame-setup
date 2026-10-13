# 11 — Mac-style keys in Game Mode (Logitech Pebble)

- **Date:** 2026-10-13
- **Status:** Active
- **Needs sudo:** No
- **Survives OS updates:** Yes (everything lives in the home folder)
- **Builds on:** [01](01-macos-keyboard.md), [02](02-remap-any-keyboard.md), [03](03-vscode.md)

## Why

The dedicated keyboard is now a **Logitech Pebble Keys 2 K380s** (Bluetooth), and the Frame stays in **Game Mode**. Desktop apps like VS Code and Konsole are launched straight from there. Switching back from Desktop Mode to Game Mode is awkward on SteamOS 0.4.5, which is why the Frame stays in Game Mode.

The xremap setup from 01–02 only runs in Desktop Mode, and it can't work in Game Mode anyway:

| | Desktop Mode | Game Mode |
|---|---|---|
| Who reads the keyboard | KWin, through the normal Linux input devices (`/dev/input/event*`) | **Steam**, directly from the raw Bluetooth HID device (`/dev/hidraw0`), which it then passes to gamescope |
| Can xremap remap it? | Yes | No. Nothing reads xremap's output, so it would have no effect |
| Where apps get keys | Wayland (KWin) | Gamescope's X servers `:0` / `:1` (Xwayland) |

Verified on 2026-10-13: with xremap running in Game Mode, no process had the keyboard's input device or xremap's virtual keyboard open. Only `steamwebhelper` had `/dev/hidraw0` (the Pebble) open.

So in Game Mode the remapping happens one step later. An **XKB layout option** on gamescope's X displays turns Cmd into Ctrl, and VS Code's own key bindings handle the rest.

## The Pebble's macOS mode

Logitech multi-OS keyboards change what the modifier keys send. Hold the key combination for about 3 seconds:

| Hold | Layout |
|---|---|
| **Fn + O** | **macOS (use this one)** |
| Fn + I | iPadOS/iOS |
| Fn + P | Windows / Android |
| Fn + C | ChromeOS |

Over Bluetooth the Pebble guesses the system by itself, and it picked Windows mode for the Frame. Measured key codes ([Logitech's guide](https://support.logi.com/hc/en-001/articles/16170851777047)):

| Key (bottom row) | Windows mode | macOS mode |
|---|---|---|
| "alt / cmd" (next to spacebar) | Alt | **Super = Cmd** |
| "start / option" | Super | **Alt = Option** |
| Strg / Ctrl | Ctrl | Ctrl |

If Cmd stops working after re-pairing, check this first: hold Fn+O again.

## What it does (Game Mode)

| Keys | Everywhere (VS Code, Konsole, browsers…) | VS Code editor | VS Code terminal (Claude Code) |
|---|---|---|---|
| Cmd+C / V / X / Z / S / A / F / W / Q / P / T… | same as Ctrl+… (so they work as on a Mac) | | |
| Cmd+C | | copy | copy if text is selected, otherwise stop the program (from 03) |
| Cmd+V | | paste | paste (from 03) |
| Cmd+← / → | | line start / end | line start / end |
| Cmd+↑ / ↓ | | top / bottom of file | — |
| Option+← / → | | jump by word | jump by word (already worked via `~/.inputrc`) |
| Option+Backspace / Cmd+Backspace | | delete word / to line start | delete word / to line start |
| Cmd+Option+↑ / ↓ | | add cursor above / below | — |
| + Shift on any of the arrow keys above | | selects | — |

**Not covered in Game Mode** (xremap did these in Desktop Mode, but Game Mode has no per-app rules):

- **Konsole:** Cmd+C is Ctrl+C, which stops the running program. Cmd+V is Ctrl+V, which inserts the next key literally and causes the `^[[200~` garbage described in 01. In Konsole, use **Cmd+Shift+C / Cmd+Shift+V**. The VS Code terminal doesn't have this problem.
- **Cmd+Z in a terminal** is Ctrl+Z, which suspends the running program (including Claude Code). Type `fg` to bring it back.
- Cmd+Tab and Cmd+Space: window switching in Game Mode is handled by Steam, not KWin.
- Cmd and the physical Ctrl key are now the same key as far as apps can tell. Physical Ctrl+← in VS Code also goes to line start.

## Changes made

### Files created

| File | Purpose |
|---|---|
| `~/.local/bin/mac-keys-gamemode` | Every 5 s, checks each gamescope X display (`/tmp/.X11-unix/X*`) and re-applies `setxkbmap -option altwin:ctrl_win` if it's missing. The XKB option maps the Super (Cmd) keys to Ctrl. The re-check covers X servers that restart or get their layout reset. |
| `~/.config/systemd/user/mac-keys-gamemode.service` | Runs the script while Game Mode is up (`WantedBy=gamescope-session.target`) |
| `~/.config/systemd/user/gamescope-session.target.wants/mac-keys-gamemode.service` | Symlink created by `systemctl --user enable` |

Verified: when I reset the layout on `:1` by hand, the service restored it within 5 s.

### Files modified

`~/.config/Code/User/keybindings.json`: kept the two terminal copy/paste rules from 03 and added the Cmd/Option arrow and Backspace rules above. These also apply in Desktop Mode, where xremap already sends Cmd as Ctrl. The original is at [`backups/11/vscode-keybindings.json.before`](../backups/11/vscode-keybindings.json.before).

### Unchanged

The xremap setup (01–02) stays as it was and still runs in Desktop Mode.

## Everyday use

```bash
systemctl --user status mac-keys-gamemode    # is it running?
journalctl --user -u mac-keys-gamemode       # "applied … on :N" each time it (re)applies the layout
DISPLAY=:0 setxkbmap -query                  # should list: options: altwin:ctrl_win
```

## How to revert

```bash
# 1. Stop and remove the Game Mode service
systemctl --user disable --now mac-keys-gamemode.service
rm ~/.config/systemd/user/mac-keys-gamemode.service ~/.local/bin/mac-keys-gamemode
systemctl --user daemon-reload
# 2. Put Cmd back to Super right away (otherwise it resets when Game Mode restarts)
for d in :0 :1; do DISPLAY=$d setxkbmap -option ""; done
# 3. VS Code keys back to 03's version
cp ~/Works/Frame/backups/11/vscode-keybindings.json.before ~/.config/Code/User/keybindings.json
```

## Open items

- [ ] Confirm Cmd+C/V and Cmd/Option+arrows in VS Code with the Pebble.
- [ ] Check the setup still works after a full reboot into Game Mode.
- [ ] The Pebble has German key labels (Strg), but the layout here is US. Check whether Y/Z and umlauts come out as printed.
