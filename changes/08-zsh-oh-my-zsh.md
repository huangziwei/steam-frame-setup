# 08 — zsh + Oh My Zsh

- **Date:** 2026-10-12
- **Status:** Active (new Konsole windows/tabs and VS Code terminals open zsh)
- **Versions:** zsh 5.9.2 (Homebrew), Oh My Zsh commit `083c339` (2026-10-12)
- **Needs sudo:** No
- **Survives OS updates:** Yes

## Why this way

- **zsh from Homebrew.** SteamOS doesn't include zsh. A `pacman` install would be wiped by the next OS update, and if zsh were the login shell at that point, terminals would fail to open. Homebrew's ARM64 build lives in `/home` and ships its own libraries (`ncurses` etc.).
- **The default shell is set per app, not per account.** Konsole and VS Code are told to open zsh. The account's login shell stays `/bin/bash`. Changing it with `chsh` would need sudo, a password, and adding Homebrew's zsh to `/etc/shells`, and if zsh ever broke, terminals wouldn't open. With this setup, bash is always one profile switch away.
- **Oh My Zsh installed without side effects.** The official installer was run with `CHSH=no RUNZSH=no`: no login-shell change, and no zsh launched mid-install.

## What you get

- Theme `robbyrussell` (the Oh My Zsh default): `➜  Frame git:(main) ✗`
- Plugins:
  - `git`: aliases such as `gst`, `gco`, `gp`, `glog`
  - `brew`: aliases and completions
  - `uv`: completions and aliases such as `uvr` (`uv run`) and `uva` (`uv add`)
  - `rust`: completions for `cargo` / `rustup` / `rustc`
- The same PATH as bash: `~/.cargo/bin` → `~/.local/bin` → Homebrew → system. Duplicates are removed (`typeset -U path`).
- Mac-style keys in the terminal:

| Keys | Action |
|---|---|
| Option+← / → | jump by word |
| Option+Backspace | delete word (zsh default) |
| Cmd+Backspace | delete to line start (xremap sends Ctrl+U; zsh binds it to `backward-kill-line`) |

- Startup time: about 80 ms.

To change the theme or add plugins, edit `ZSH_THEME=` / `plugins=(…)` in `~/.zshrc`. Themes are listed at https://github.com/ohmyzsh/ohmyzsh/wiki/Themes. Oh My Zsh updates itself periodically (it asks first), or run `omz update`.

## Changes made

### Installed

| What | Where |
|---|---|
| zsh 5.9.2 + deps (`brew install zsh`) | `/home/linuxbrew/.linuxbrew/` |
| Oh My Zsh (git clone of `ohmyzsh/ohmyzsh`) | `~/.oh-my-zsh/` |

### Files created

| File | Purpose |
|---|---|
| `~/.zshrc` | Oh My Zsh template plus our additions (below). The untouched template is saved at [`backups/08/zshrc.omz-template`](../backups/08/zshrc.omz-template). |
| `~/.local/share/konsole/Zsh.profile` | Konsole profile: `Command=/home/linuxbrew/.linuxbrew/bin/zsh -l`, inheriting all other defaults |
| `~/.config/Code/User/settings.json` | VS Code: built-in terminal defaults to zsh (`-l`). This is VS Code's main settings file; later settings get added here too. |

Created by Oh My Zsh at runtime: `~/.zcompdump*` (completion cache) and `~/.cache/` entries.

### Additions to the Oh My Zsh template (`~/.zshrc`)

1. **Top: PATH block.** Runs `brew shellenv zsh`, adds `~/.local/bin`, then `~/.cargo/env`, with `typeset -U path`.
2. **Plugins:** `plugins=(git)` changed to `plugins=(git brew uv rust)`.
3. **Bottom: key bindings.** `^[[1;3D` → `backward-word`, `^[[1;3C` → `forward-word`, `^U` → `backward-kill-line`.
4. **Bottom:** `export SHELL=/home/linuxbrew/.linuxbrew/bin/zsh`. This makes programs started from zsh that spawn "your shell" (tmux, editors) use zsh. The login shell is still bash.

### Settings modified

`~/.config/konsolerc` (original saved at [`backups/08/konsolerc.before`](../backups/08/konsolerc.before)). Added:

```ini
[Desktop Entry]
DefaultProfile=Zsh.profile
```

## Verified

- In a test terminal: interactive zsh starts with no errors, and the prompt is `➜  Frame`.
- Commands resolve to the right places: `uv`, `uvx`, `code` → `~/.local/bin`; `cargo`, `rustc` → `~/.cargo/bin`; `brew`, `zsh` → Homebrew; `python3` → `/usr/bin/python3` (system, untouched).
- Completions loaded for `uv`, `cargo` and `brew`. Key bindings present.
- `konsole --list-profiles` shows `Zsh` (next to SteamOS's `Vapor`).
- `zsh -l -i` works (login + interactive), with `SHELL` set to Homebrew zsh.

## Using bash again

- **One Konsole tab:** Konsole menu → *New Tab* → choose the **Vapor** profile.
- **Back to bash by default:** Konsole → *Settings → Manage Profiles…* → select **Vapor** → *Set as Default*.

## How to revert

```bash
# Konsole back to the SteamOS default profile
cp ~/Works/Frame/backups/08/konsolerc.before ~/.config/konsolerc
rm ~/.local/share/konsole/Zsh.profile

# VS Code terminal back to bash: delete the two "terminal.integrated.*" entries from
# ~/.config/Code/User/settings.json (or the whole file if nothing else has been added)

# Remove Oh My Zsh and zsh config
rm -rf ~/.oh-my-zsh ~/.zshrc ~/.zcompdump*
brew uninstall zsh && brew autoremove
```
