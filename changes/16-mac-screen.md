# 16 — The Mac's screen in a window on the Frame (`mac`)

- **Date:** 2026-10-14
- **Status:** Active
- **Needs sudo:** No
- **Survives OS updates:** Yes (user Flatpak and `~/.local/bin` live in the home folder)

## Why

Working on the Frame and the Mac mini in turn meant taking the headset off and on again and again. Now the Mac's screen opens as a window inside the headset, next to the terminal, and you can type and click on the Mac through it.

## How it works

- **Mac:** the built-in **Screen Sharing** (a VNC server), reached over Tailscale ([15](15-tailscale.md)) at `mac-mini-von-ziwei`.
- **Frame:** **Remmina**, a remote desktop viewer, from Flathub. It logs in with the Mac's normal username and password (Apple's login method), so the Mac's separate, weak 8-character "VNC password" stays off.

It shows the Mac's **live** screen. That's the opposite direction from the Windows App in 15, which opens a separate session on the Frame.

## Setting up the Mac (once)

System Settings → General → Sharing → **Screen Sharing** on → ⓘ:
- Allow access for: **Only these users** → your account (`ziweih`)
- **"VNC viewers may control screen with password": off**

Screen Sharing listens on port 5900 on every network the Mac is on, including the campus network. Logging in still needs the Mac password.

## Using it

```bash
mac
```
Remmina asks for the Mac password (tick **Save password** to stop being asked). Close the window to disconnect.

**Two displays:** macOS sends both of the Mac's displays as one wide picture. Only Apple's own Screen Sharing app can pick a single display. The Mac only listens on port 5900, not the per-display ports 5901/5902 that some guides mention. So the profile shows the picture at full size (`scale=0`) in "scrolled fullscreen" (`viewmode=3`), and you scroll to the display you want. The Remmina toolbar switches between scaled, scrolled and viewport modes, and Remmina remembers the choice.

**Toolbar "View only":** while it's on, the Mac ignores your keyboard and mouse.

**Right Cmd:** Remmina's shortcut key is Right Ctrl, and in Game Mode Right Cmd *is* Right Ctrl ([11](11-mac-keys-game-mode.md)). So Right Cmd may trigger Remmina actions instead of reaching the Mac. Use the left Cmd for Mac shortcuts.

## Changes made

### Installed

| What | How |
|---|---|
| Remmina 1.4.43 (`org.remmina.Remmina`) + GNOME 49 runtime | `flatpak install --user flathub org.remmina.Remmina`, about 1.5 GB in `~/.local/share/flatpak` |

**Per-user Flatpak, not system:** a system install (what Discover does) needs your password. Its password prompt sat unseen in Game Mode, so the install hung. A per-user install needs no password, but it can't reuse the system's runtimes, so it downloads its own (bigger, slower first install).

### Files created

| File | Contents |
|---|---|
| Flatpak remote `flathub` (user) | `flatpak remote-add --user flathub …` (the system already had one) |
| `~/.local/bin/mac` | Launches Remmina with the Mac profile in the background. Creates the profile on first run. Copy in `home/`. |
| `~/.var/app/org.remmina.Remmina/data/remmina/mac-mini.remmina` | The connection profile: server, user, quality, view mode. **Not** in `home/`: Remmina rewrites it with toolbar changes and a saved password. Delete it to get the defaults from `mac` back. |
| `~/.var/app/org.remmina.Remmina/config/remmina/remmina.pref` | Remmina's own preferences, including the key that encrypts saved passwords. Created by Remmina. |

## Updating

```bash
flatpak update
```

## How to revert

```bash
flatpak uninstall --user --delete-data org.remmina.Remmina
flatpak uninstall --user --unused          # removes the GNOME runtime it pulled in
rm ~/.local/bin/mac
```
On the Mac: System Settings → General → Sharing → Screen Sharing off.
