# 07 — Homebrew (for command-line tools)

- **Date:** 2026-10-12
- **Status:** Active
- **Installed by:** you, around 15:49 on 2026-10-12, outside our session. This entry records it, plus the shell setup added afterwards.
- **Version:** Homebrew 7.0.9, prefix `/home/linuxbrew/.linuxbrew`
- **Needs sudo:** Only for the initial install, which created `/home/linuxbrew`. Not for using it.
- **Survives OS updates:** Yes. It lives under `/home`, which SteamOS updates don't touch.

## Policy

**Use Homebrew for command-line tools.** It works the same as on macOS (`brew install`, `brew upgrade`) and installs ready-made ARM64 Linux builds ("bottles") with their own libraries.

Exceptions, for tools that manage themselves:

| Tool | Managed by | Update with |
|---|---|---|
| uv + Python | uv itself ([05](05-uv.md)) | `uv self update` |
| Rust | rustup ([06](06-rust.md)) | `rustup update` |
| VS Code | `code-update` ([03](03-vscode.md)) | `code-update` |

Casks (graphical apps) are mostly macOS-only. For example, the VS Code cask's Linux entry is an empty placeholder.

## Health check (`brew doctor`, 2026-10-12)

The only warning was "Landlock is not supported by this Linux kernel". That concerns Homebrew's optional sandbox for building packages from source. Installing prebuilt bottles isn't affected.

## Changes made

### Settings modified

`~/.bashrc` (original saved at [`backups/07/bashrc.before`](../backups/07/bashrc.before)). These lines were added right before the `~/.local/bin` PATH line:

```bash
# Homebrew (Works/Frame change 07). Before ~/.local/bin so our own tools (uv, code, xremap) win over brew ones.
[ -x /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

The resulting PATH order is: `~/.cargo/bin` → `~/.local/bin` → Homebrew → system.

`~/.zshrc` has the same setup; see [08](08-zsh-oh-my-zsh.md).

### Packages installed through brew so far

| Formula | Why |
|---|---|
| `zsh` 5.9.2 | [08](08-zsh-oh-my-zsh.md) |
| `ncurses`, `pcre2`, `bzip2`, `zlib-ng-compat` | Dependencies of zsh |

## Caveat

If a brew formula ever pulls in Python as a dependency, Homebrew's `python3` would come before `/usr/bin/python3` in your terminals. SteamOS's own scripts don't use your terminal PATH, so they're unaffected. For your own work, use `uv run` and `uv`'s Pythons anyway.

## How to revert

Remove only the shell setup (keep Homebrew installed): delete the two Homebrew lines from `~/.bashrc` and the `brew shellenv` line from `~/.zshrc`.

Uninstall Homebrew completely: first uninstall its packages (or accept that zsh, [08](08-zsh-oh-my-zsh.md), goes with it), then run Homebrew's official uninstaller:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```

Removing `/home/linuxbrew` itself needs sudo.
