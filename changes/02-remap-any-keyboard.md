# 02 — Apply the Mac-style keys to any keyboard

- **Date:** 2026-10-12
- **Status:** Active
- **Needs sudo:** No
- **Builds on:** [01 — macOS-style keyboard](01-macos-keyboard.md)

## Why

Change 01 only remapped devices named "Magic Keyboard", so any other keyboard (for example a Logitech Pebble) would have kept the plain Linux layout. Now xremap remaps **every keyboard**, including ones paired later: `--watch=device` picks them up as soon as they connect. Only the headset's own built-in input devices are excluded.

## Changes made

`~/.config/systemd/user/xremap.service`, the `ExecStart=` line:

| | Value |
|---|---|
| Before | `xremap --watch=device,config --device "Magic Keyboard" …/config.yml` |
| After | `xremap --watch=device,config --ignore pmic_pwrkey --ignore pmic_resin --ignore gpio-keys --ignore steamos-manager --ignore als31300 …/config.yml` |

The ignored devices are the headset's own built-in inputs:

| Device | What it likely is |
|---|---|
| `pmic_pwrkey` | power button |
| `pmic_resin` | power-chip reset/volume input |
| `gpio-keys` | hardware buttons |
| `steamos-manager` | SteamOS's own virtual input device |
| `als31300` | a hardware sensor |

The original file is saved at [`backups/02/xremap.service.before`](../backups/02/xremap.service.before).

Verified after the change: xremap selected only `/dev/input/event5 : Magic Keyboard`.

## Notes for non-Apple keyboards

The rules treat the **Super/Win/Cmd** key as Cmd.

- **Logitech Pebble and other multi-OS keyboards:** switch the keyboard to its **macOS mode**. On most Logitech models you hold **Fn+O** for about 3 seconds; check the keyboard's manual. In that mode, the key next to the spacebar sends Cmd, matching the Mac layout.
- **PC-only keyboards** (Ctrl · Win · Alt order): the Cmd role lands on the Win key, one key further from the spacebar than on a Mac. If that bothers you, add a per-device rule in `~/.config/xremap/config.yml` that swaps Alt and Win for that keyboard (`modmap` with `device: only: '<name>'`). You can get the exact device name with `~/.local/bin/xremap --list-devices`.

## How to revert (back to Magic-Keyboard-only)

```bash
cp ~/Works/Frame/backups/02/xremap.service.before ~/.config/systemd/user/xremap.service
systemctl --user daemon-reload
systemctl --user restart xremap
```
