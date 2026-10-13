# 14 — VS Code without built-in AI; Claude Code from the terminal only

- **Date:** 2026-10-13
- **Status:** Active
- **Needs sudo:** No
- **In `setup.sh`:** yes (steps `vscode` and `claude`)

## Why

VS Code 1.141 ships GitHub Copilot as a **built-in** extension (`GitHub.copilot-chat` 0.69.0, inside VS Code itself). Its Chat view sits in the right-hand ("secondary") side bar, and that bar kept reopening even after you closed it. You don't want any of VS Code's own AI features. You also don't want the Claude Code extension: Claude Code runs only in the integrated terminal.

## What it does

| Problem | Fix |
|---|---|
| Copilot chat, inline suggestions, next-edit suggestions, and the Chat view and buttons | `"chat.disableAIFeatures": true`, VS Code's single switch that turns off and hides all built-in AI features |
| The right side bar reopening | `"workbench.secondarySideBar.defaultVisibility": "hidden"`. The default, `visibleInWorkspace`, reopens it whenever a folder is opened. |
| Claude Code extension | Uninstalled |
| …and reinstalled automatically | By default, Claude Code reinstalls its VS Code extension each time it starts in VS Code's terminal. `CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL=1` in Claude Code's settings turns that off. |

Without the extension, Claude Code in the terminal works the same. What's gone is the IDE link: diffs shown in VS Code's diff view, and Claude seeing the file or selection open in the editor (`/ide`).

## Changes made

### Settings modified

`~/.config/Code/User/settings.json`: added these two keys (the zsh terminal settings from 08 are unchanged):

```jsonc
"chat.disableAIFeatures": true,
"workbench.secondarySideBar.defaultVisibility": "hidden"
```

`~/.claude/settings.json`: added this block. The previous file is saved at [`backups/14/claude-settings.json.before`](../backups/14/claude-settings.json.before).

```json
"env": { "CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL": "1" }
```

### Removed

The VS Code extension `anthropic.claude-code` 2.1.296 (`code --uninstall-extension anthropic.claude-code`). Its folder in `~/.vscode/extensions/` is deleted the next time VS Code reloads.

### `setup.sh`

- The `vscode` step no longer installs the Claude extension. If the extension is present, the step removes it.
- The `claude` step now always applies the `env` values from `home/.claude/settings.json`, on top of any env values already on the device.
- `home/` holds the new versions of both settings files.

## To finish

**Reload VS Code:** Cmd+Shift+P → "Developer: Reload Window", or quit and reopen. This unloads the extension and closes the Chat view.

Programs running in the integrated terminal usually survive a reload, because VS Code reconnects to them. To be safe, finish what you're doing in Claude Code first; you can resume with `claude --continue`.

## How to revert

```bash
# VS Code: delete the two keys above from ~/.config/Code/User/settings.json, then:
code --install-extension anthropic.claude-code
# Claude Code: restore the previous settings (removes the env block)
cp ~/Works/Frame/backups/14/claude-settings.json.before ~/.claude/settings.json
```

## Open items

- [ ] After a reload: the Chat side bar stays closed, and no Claude extension reappears after starting `claude` in the terminal.
