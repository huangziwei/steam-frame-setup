# 13 — `setup.sh`: set up another Frame the same way

- **Date:** 2026-10-13
- **Status:** Active
- **Needs sudo:** Only on a new Frame, once, for installing Homebrew. The script asks for it.

## Why

A second Steam Frame is coming. Instead of repeating changes 01–12 by hand, the repo now contains a script that reproduces them, plus copies of the exact config files from this Frame.

## How to use it on a new Frame

1. Set up SteamOS (Wi-Fi, Steam login), then open **Konsole**. It can be launched from Game Mode.
2. Run:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/huangziwei/steam-frame-setup/main/bootstrap.sh | bash
   ```
   This downloads the repo to `~/Works/Frame` and starts `./setup.sh`. It works because the repo is public.
3. Answer its two interactive steps:
   - **Password:** if `steamos` has no password yet, the script runs `passwd` so you can choose one. It's then used once by sudo, to install Homebrew.
   - **GitHub key:** the script shows the new public key (and opens it in VS Code). Paste it at https://github.com/settings/ssh/new, then press Enter. `s` skips this for now.
4. When it's done it lists what's left for you:
   - pair the Pebble and hold **Fn+O**
   - run `claude` to sign in
5. Open a new terminal to get zsh.

Re-running is safe: finished steps are skipped and files that are already right are left alone. Run single steps with `./setup.sh vscode keyboard`; see all of them with `./setup.sh --list`.

## Steps

| Step | Does | From change |
|---|---|---|
| `sudo` | Sets a password if needed (only when Homebrew isn't installed yet) | 07 |
| `homebrew` | Homebrew's official installer | 07 |
| `git` | `brew install git`, name/email, `main` as the default branch | 12 |
| `shell` | `brew install zsh`, Oh My Zsh, `~/.bashrc` `~/.zshrc` `~/.inputrc` | 05–08 |
| `konsole` | Zsh profile as Konsole's default | 08 |
| `uv` | uv (official installer, no shell edits) and the newest Python | 05 |
| `rust` | `rustup-init` (SHA-256 checked) with the same flags as 06 | 06 |
| `vscode` | `code-update`, `code` command, launchers, `vscode://` handler, settings (built-in AI off), Mac key bindings. Removes the Claude extension if present. | 03, 08, 11, 14 |
| `keyboard` | xremap 0.15.14 (pinned, SHA-256 checked), its config and service, the Game Mode Cmd=Ctrl service, Cmd+Tab | 01, 02, 11 |
| `desktop` | 1920×1080 Desktop Mode override | 04 |
| `claude` | Claude Code (official installer). Sets the status line and the `env` values (no VS Code extension auto-install); other keys in `~/.claude/settings.json` are only added when missing. | 10, 14 |
| `github` | SSH key, GitHub host key checked against GitHub's published fingerprint, waits until GitHub accepts the key, switches this repo to SSH | 12 |
| `claude-usage` | Clones `huangziwei/claude-usage` and runs `uv tool install --editable` | 10 |
| `tailscale` | `tailscale-update` (installs Tailscale, SHA-256 checked, needs sudo), asks for a name (default `frame2`), prints a sign-in link | 15 |
| `mac-screen` | Remmina from Flathub (user install, ~1.5 GB with its runtime, shows progress) and the `mac` command | 16 |

Versions: most tools install their **latest** release, each with its own checksum check. Only xremap is pinned (0.15.14), because its key-config format could change between versions.

## What stays manual

- Choosing the password (the script prompts) and pasting the SSH key on github.com.
- Bluetooth pairing of the Pebble and **Fn+O** (macOS mode).
- Signing in: Claude Code, and VS Code accounts if you use them.
- Tailscale: opening the sign-in link (on the Mac is fine), then **Disable key expiry** for the new Frame in the Tailscale admin page.
- Turning on Screen Sharing on the Mac, and typing the Mac password the first time `mac` connects.
- Adding VS Code or Konsole to the Steam library, if you launch them that way in Game Mode.
- The 1920×1080 desktop (04) and Cmd+Tab (01) take effect the next time Desktop Mode starts.

## Files

| Path (in this repo) | Purpose |
|---|---|
| `bootstrap.sh` | The `curl … \| bash` entry point: clones the repo over HTTPS, then runs `setup.sh` |
| `setup.sh` | The steps above |
| `home/` | Copies of this Frame's files, same layout as `~`. `/home/steamos` inside them is replaced with the new device's home folder. |

Files that already exist on the new device with different content are backed up to `~/.local/state/frame-setup/backup-<date-time>/` before being replaced.

### Keeping `home/` in sync with this Frame

When a config file changes here, update the repo copy too:

```bash
./setup.sh --diff      # what differs between home/ and this device
./setup.sh --collect   # copy this device's versions into home/, then commit
```

A new kind of change, such as a new tool, also needs its own step in `setup.sh`.

## Also changed

- `~/.config/systemd/user/xremap.service`: the description said "(Magic Keyboard)", left over from 01. It now says "(Desktop Mode)". Nothing else changed.
- `~/Works/claude-usage`: first git commit, pushed to the public repo `git@github.com:huangziwei/claude-usage.git`.

## Verified

- **This Frame:** a full `./setup.sh` run finished with every step "already up to date". No files were replaced and nothing was backed up.
- **Empty test home folder:** `shell konsole desktop claude` ran there.
  - It installed the files and Oh My Zsh, and kept our `~/.zshrc`.
  - It wrote the Konsole default.
  - It merged `~/.claude/settings.json`: existing `theme`/`tui` were kept, `statusLine` was added, and its path was rewritten to the test home.
  - This test found and fixed a bug: a `ZSH` variable left over from the calling shell made the Oh My Zsh installer target the wrong folder.
- **ShellCheck:** only notes about intentional things (`~` in display text, a stdin redirect for sudo).
- **Downloads:** the pinned xremap download matches its checksum. The `rustup-init.sha256` format matches what the script parses.

Not tested yet: a run on a real fresh Frame (sudo, Homebrew install, the GitHub key prompt).

## How to revert

Delete `setup.sh`, `bootstrap.sh` and `home/` from the repo. Nothing on this Frame depends on them.

## Open items

- [x] `huangziwei/steam-frame-setup` made public (2026-10-13).
- [x] Repo `huangziwei/claude-usage` created (as a **public** repo) and pushed (2026-10-13).
- [ ] First real run on the second Frame. Record anything that went wrong here.
