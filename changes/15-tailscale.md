# 15 — Tailscale: reach the Frame by name from the Mac

- **Date:** 2026-10-14
- **Status:** Active
- **Needs sudo:** Yes (install and updates)
- **Survives OS updates:** Yes (programs in `/var`, service and settings in `/etc`, which SteamOS keeps)

## Why

SSH, remote desktop (Windows App) and Steam Link from the Mac mini all need the Frame's address. On eduroam the Wi‑Fi IP keeps changing, so it had to be looked up every time.

Tailscale is a private network between your own devices. Each device gets a **fixed** address (`100.x.y.z`) and a **name**, wherever it is: eduroam, home, a phone hotspot. On campus the traffic goes directly between the two devices (measured: ~7 ms, not through a relay) and is encrypted (WireGuard).

Alternatives considered:
- **`frame.local` (Bonjour/mDNS):** already works on the Frame itself, but the Mac mini is on another campus subnet (`134.2.56.x` vs the Frame's `134.2.104–111.x`), and mDNS doesn't cross subnets. It also never works off campus.
- **Dynamic DNS:** would publish an internal campus IP in public DNS, and it still wouldn't work off campus.

## Account and devices

- Tailscale account: signed in with **GitHub** (`huangziwei`). Free personal plan.
- Network name: `tail3385c1.ts.net`. Admin page: <https://login.tailscale.com/admin/machines>

| Device | Tailscale name | Fixed address |
|---|---|---|
| This Frame | `frame` | `100.81.167.113` |
| Mac mini | `mac-mini-von-ziwei` | `100.72.11.70` |
| Second Frame | `frame2` (set by `setup.sh`) | — |

**Key expiry:** by default Tailscale signs each device out after 180 days. For the Frames, turn that off once on the admin page: Machines → `frame` → `⋯` → **Disable key expiry**.

## Using it from the Mac

The Tailscale app must be running on the Mac (menu bar icon, "Connected").

| What | How |
|---|---|
| SSH | `ssh steamos@frame` |
| Windows App (remote desktop) | Edit the PC → PC name: `frame` (or `100.81.167.113`) |
| Steam Link | Where you entered the Frame's IP before, enter `100.81.167.113` |

Optional, on the Mac, so plain `ssh frame` works: add to `~/.ssh/config`
```
Host frame frame2
    User steamos
```

**Remote desktop opens a separate session.** The Windows App talks to `xrdp`, which comes with SteamOS and was already running. `xrdp` starts its **own** desktop session; it doesn't show the Desktop Mode currently in the headset. Seeing the live screen would need a different tool and is not part of this change.

**Firewall:** unchanged. The Frame's firewall (firewalld, zone `public`) already allowed SSH and ports 1024–65535, which include remote desktop (3389), Steam streaming (27031–27037) and Tailscale's own port (41641). Traffic arriving through Tailscale uses the same rules.

## Changes made

### Installed

| What | Where |
|---|---|
| Tailscale 1.104.1 (official static arm64 build from pkgs.tailscale.com, SHA-256 checked) | `/var/opt/tailscale/tailscale`, `/var/opt/tailscale/tailscaled` (owned by root) |

**Not Homebrew**, unlike other command-line tools ([07](07-homebrew.md)): `tailscaled` runs as root, and Homebrew's folder is writable by your normal user. Any program running as you could then replace it and gain root. The root-owned folder avoids that.

### Files created

| File | Contents |
|---|---|
| `~/.local/bin/tailscale-update` | Installs / updates Tailscale, then signs in if needed (`--hostname NAME` sets the device name). Copy in `home/`. |
| `~/.local/bin/tailscale` | Symlink to `/var/opt/tailscale/tailscale`, so `tailscale` is on PATH |
| `/etc/systemd/system/tailscaled.service` | Tailscale's own unit file, with paths changed to `/var/opt/tailscale`. Enabled: starts at boot. |
| `/etc/default/tailscaled` | Tailscale's default settings (port 41641) plus `TS_DEBUG_FIREWALL_MODE=nftables`. The SteamOS kernel has no legacy iptables modules, so without this line Tailscale shows a health warning. |
| `/var/lib/tailscale/` | Created by Tailscale: this device's identity and sign-in. Deleting it signs the device out. |

Signed in with `tailscale up --operator=steamos`, so `tailscale` commands work without sudo. MagicDNS also works on the Frame: `ssh mac-mini-von-ziwei` resolves.

## Updating

```bash
tailscale-update
```
It does nothing if the newest version is already installed. Tailscale's own auto-update doesn't apply to this kind of install.

## How to revert

```bash
sudo tailscale logout                       # also removes the device from the admin page
sudo systemctl disable --now tailscaled.service
sudo rm /etc/systemd/system/tailscaled.service /etc/default/tailscaled
sudo systemctl daemon-reload
sudo rm -r /var/opt/tailscale /var/lib/tailscale /var/cache/tailscale
rm ~/.local/bin/tailscale ~/.local/bin/tailscale-update
```
On the Mac: quit Tailscale and delete the app. Then go back to using the Wi‑Fi IP (`ip -4 addr show wlan0` on the Frame).
