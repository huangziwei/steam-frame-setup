# 03 — Visual Studio Code

- **Date:** 2026-10-12
- **Status:** Active
- **Version installed:** 1.141.0 (commit `2a59476c`), linux-arm64, Microsoft's official build
- **Needs sudo:** No
- **Survives OS updates:** Yes (everything lives in the home folder)

## Why this way

| Option | Verdict |
|---|---|
| **Official `.tar.gz` unpacked into `~/.local/opt`** ✅ | Microsoft's own build at the latest version. It survives SteamOS updates and has no sandbox, so the built-in terminal and extensions can see every tool on the system. The one downside is no automatic updates, which `code-update` covers. |
| `.deb` / `.rpm` (the big buttons on code.visualstudio.com) | Package formats for Debian/Ubuntu and Fedora. SteamOS is based on Arch Linux and uses neither. The `.tar.gz` is the small link under the **Arm64** column on the download page. |
| Flatpak via Discover | Packaged by the community, not Microsoft, and was a version behind (1.139.1). Its sandbox hides system tools from the terminal and extensions. |
| Homebrew cask | The cask's `arm64_linux` entry was an empty placeholder (it points to the macOS download, with no version), so it can't install here. |
| `pacman` / AUR | SteamOS wipes these installs on every OS update. |

## Everyday use

```bash
code .                 # open the current folder (same as on macOS)
code-update            # update to the latest release (quit VS Code first)
code-update --rollback # go back to the previous version
```

You can also open it from the app launcher (Cmd+Space, then type "code").

VS Code tells you when an update is available, but this kind of install can't update itself. When it does, quit VS Code and run `code-update`. The script downloads from Microsoft, checks the SHA-256 checksum, and keeps the old version in `~/.local/opt/vscode.previous`.

## Changes made

### Files created

| File | Purpose |
|---|---|
| `~/.local/opt/vscode/` | VS Code itself (unpacked from `code-stable-arm64-1791276594.tar.gz`, SHA-256 `3b6ea238a2aa9000bab0137c19f06d4e8edcb5587438a3afc9dc9739e793e934`, verified against Microsoft's update API) |
| `~/.local/bin/code-update` | Install, update, and rollback script |
| `~/.local/bin/code` | Symlink to `~/.local/opt/vscode/bin/code` (the terminal `code` command) |
| `~/.local/share/applications/code.desktop` | App-launcher entry. Based on Microsoft's official Linux launcher file, with paths pointing to `~/.local/opt/vscode` |
| `~/.local/share/applications/code-url-handler.desktop` | Opens `vscode://` links in VS Code (needed for GitHub/Microsoft sign-in) |
| `~/.config/Code/User/keybindings.json` | Mac-style copy/paste in the built-in terminal (see below) |

Created automatically by the tools I ran:

- `~/.local/share/applications/mimeinfo.cache` (rebuilt by `update-desktop-database`)
- the KDE app-menu cache (rebuilt by `kbuildsycoca6`)
- `~/.config/Code/`: VS Code's settings and state, created on first launch
- `~/.vscode/`: extensions, created on first launch

### Settings modified

`~/.config/mimeapps.list`, under `[Default Applications]`. This line was added by `xdg-mime`:

```
x-scheme-handler/vscode=code-url-handler.desktop
```

The existing line `x-scheme-handler/claude-cli=claude-code-url-handler.desktop` was left untouched.

### Terminal copy/paste in VS Code

Because of [change 01](01-macos-keyboard.md), Cmd arrives in VS Code as Ctrl, so Cmd+C and Ctrl+C look identical to VS Code. `keybindings.json` makes the built-in terminal behave like the Mac's:

| Keys | Behavior |
|---|---|
| Cmd+C **with text selected** | copies and clears the selection, so the next Cmd/Ctrl+C interrupts again |
| Cmd+C or Ctrl+C **with nothing selected** | interrupts the running program (SIGINT), as usual |
| Cmd+V | pastes. Without this binding, Linux VS Code would send a raw Ctrl+V to bash and cause the same `^[[200~` stray characters as before. |

## Verified

- `code --version` reports 1.141.0, arm64.
- `code-update` correctly reports "already the latest" when run again.
- Launcher entries pass `desktop-file-validate` (only cosmetic hints).
- VS Code launches and connects natively via Wayland, which keeps text sharp. The startup log shows only routine Chromium warnings: no hardware video decoding, an unreadable dark-mode setting, and deprecation notices.

## How to revert

Quit VS Code first, then:

```bash
rm -rf ~/.local/opt/vscode ~/.local/opt/vscode.previous
rm ~/.local/bin/code ~/.local/bin/code-update
rm ~/.local/share/applications/code.desktop ~/.local/share/applications/code-url-handler.desktop
update-desktop-database ~/.local/share/applications && kbuildsycoca6
sed -i '/^x-scheme-handler\/vscode=/d' ~/.config/mimeapps.list

# Optional: also delete your VS Code settings and extensions
rm -rf ~/.config/Code ~/.vscode
```
