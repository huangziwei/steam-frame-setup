# Steam Frame — Setup Log

A record of every change made to this Steam Frame (SteamOS, KDE Plasma 6 on Wayland, aarch64), with how to undo each one.

## Setting up a new Frame

```bash
curl -fsSL https://raw.githubusercontent.com/huangziwei/steam-frame-setup/main/bootstrap.sh | bash
```

This runs [`setup.sh`](setup.sh), which redoes changes 01–12 and 14 using the config files in [`home/`](home/). It asks for a password (once, for Homebrew) and for you to paste an SSH key on GitHub. See [13](changes/13-setup-script.md) for details.

## Changes

Each change has its own file in [`changes/`](changes/). Every file lists what was changed, why, the exact files touched, and the commands to revert it.

| # | Date | Change | Status | Needs sudo |
|---|------|--------|--------|------------|
| 01 | 2026-10-12 | [macOS-style keyboard (Magic Keyboard)](changes/01-macos-keyboard.md) | Active | No |
| 02 | 2026-10-12 | [Apply the Mac-style keys to any keyboard](changes/02-remap-any-keyboard.md) | Active | No |
| 03 | 2026-10-12 | [Visual Studio Code 1.141.0 (official arm64 build)](changes/03-vscode.md) | Active | No |
| 04 | 2026-10-12 | [Full-width desktop: KWin at 1920×1080 (no black bars)](changes/04-desktop-resolution.md) | Active | No |
| 05 | 2026-10-12 | [uv 0.13.0 + uv-managed Python 3.15.0](changes/05-uv.md) | Active | No |
| 06 | 2026-10-12 | [Rust 1.99.0 via rustup](changes/06-rust.md) | Active | No |
| 07 | 2026-10-12 | [Homebrew 7.0.9 (installed by you) + shell setup](changes/07-homebrew.md) | Active | Install only |
| 08 | 2026-10-12 | [zsh 5.9.2 + Oh My Zsh as the terminal shell](changes/08-zsh-oh-my-zsh.md) | Active | No |
| 09 | 2026-10-12 | [Claude Code status line (robbyrussell style)](changes/09-claude-statusline.md) | Replaced by 10 | No |
| 10 | 2026-10-12 | [Claude status line + usage tracking (`claude-usage`)](changes/10-claude-usage-statusline.md) | Active | No |
| 11 | 2026-10-13 | [Mac-style keys in Game Mode (Logitech Pebble)](changes/11-mac-keys-game-mode.md) | Active | No |
| 12 | 2026-10-13 | [git 2.56 (Homebrew) + GitHub over SSH](changes/12-git-github-ssh.md) | Active | No |
| 13 | 2026-10-13 | [`setup.sh`: set up another Frame the same way](changes/13-setup-script.md) | Active | New Frame only |
| 14 | 2026-10-13 | [VS Code without built-in AI; Claude Code from the terminal only](changes/14-vscode-no-ai.md) | Active | No |

## Commands added

| Command | What it does |
|---|---|
| `code` | Open VS Code (`code .` opens the current folder) |
| `code-update` | Update VS Code (`--rollback` returns to the previous version) |
| `systemctl --user restart xremap` | Restart the keyboard remapper (Desktop Mode) |
| `systemctl --user restart mac-keys-gamemode` | Restart the Cmd-as-Ctrl layout fix (Game Mode) |
| `uv` / `uvx` | Python projects, packages, and Python versions (`uv self update` to update) |
| `cargo` / `rustup` | Rust builds and toolchains (`rustup update` to update) |
| `brew` | Command-line tools (`brew upgrade` to update all) |
| `git` | git 2.56 from Homebrew; GitHub via SSH (`ssh -T git@github.com` to test) |
| `omz update` | Update Oh My Zsh |
| `claude-usage` | Claude Code cost/token report (`daily`, `weekly`, `monthly`, `sessions`) |
| `./setup.sh --diff` / `--collect` | Compare / sync this Frame's config files with the repo's `home/` (in `~/Works/Frame`) |

## Where things get installed

| Kind of thing | Installed with |
|---|---|
| Command-line tools | Homebrew (`brew install …`) |
| Python + packages | uv |
| Rust | rustup |
| VS Code | `code-update` |
| Never | `pacman` (SteamOS updates wipe it) |

**Shells:** new terminals (Konsole, VS Code) open **zsh + Oh My Zsh** (`~/.zshrc`). The account's login shell is still bash (`~/.bashrc`), and both files set the same PATH.

Original copies of files changed after creation are kept in [`backups/NN/`](backups/).

## Things worth knowing about SteamOS

- **Changes to the system itself don't last.** The system part of SteamOS (`/usr`) is read-only and gets replaced on every OS update, a bit like macOS's protected system volume. Anything installed there with `pacman` disappears after an update.
- **Your home folder is safe.** `/home/steamos` survives updates, which is why everything here is kept under `~/.local`, `~/.config`, or in containers.
- **Admin access.** The `steamos` account is already an admin (in the `wheel` group), but there's no password until you set one with `passwd`. sudo doesn't work until then.
- **Background services** can run as your user, without sudo. Manage them with `systemctl --user ...`.
- **Game Mode is the everyday mode.** Desktop apps (VS Code, Konsole) can be launched straight from it. In Game Mode Steam reads the keyboard itself, so keyboard remapping works differently there than in Desktop Mode. See [11](changes/11-mac-keys-game-mode.md).
- **Desktop mode runs inside VR.** KWin draws the desktop as a window inside gamescope, Steam's compositor, which shows it as a large virtual screen in the headset. Restarting KWin restarts the whole desktop and closes all apps. See [04](changes/04-desktop-resolution.md).

## Device snapshot (2026-10-12)

| | |
|---|---|
| OS | SteamOS (`holo`, Arch-based), kernel 6.18, aarch64 |
| Desktop | KDE Plasma 6.2.5, Wayland |
| Terminal | Konsole 24.02.2, bash 5.3.3 |
| User | `steamos` (groups include `wheel`, `input`) |
| Keyboard | Apple Magic Keyboard (Bluetooth), US layout, model `apple`. Since 2026-10-13: Logitech Pebble Keys 2 K380s (Bluetooth, macOS mode), the dedicated keyboard |
