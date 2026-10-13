# 09 — Claude Code status line (robbyrussell style)

- **Date:** 2026-10-12
- **Status:** Replaced by [10](10-claude-usage-statusline.md) on 2026-10-12 (you wanted a Claude-specific status line, not a copy of the shell prompt)
- **Set up by:** the `/statusline` command (Claude Code's status-line helper). Tested in this session.
- **Needs sudo:** No

## What it does

Claude Code's bottom status line mirrors the Oh My Zsh prompt from [08](08-zsh-oh-my-zsh.md):

```
➜  Frame git:(main) ✗
```

- `➜`: bold green. It's always green, because the status line can't see a previous command's exit status, so it never turns red like the shell prompt does.
- Folder name: cyan.
- `git:(branch)`: blue/red, shown only inside a git repo. Shows a short commit hash on a detached HEAD.
- `✗`: yellow, shown when the repo has uncommitted changes.
- Uses `git --no-optional-locks`, so it never blocks git commands you're running.
- Parses Claude Code's JSON input with `python3 -I` (no `jq` needed).

## Changes made

### File created

`~/.claude/statusline-command.sh` is the status-line script, run with `bash`, so it doesn't need to be executable.

### Settings modified

`~/.claude/settings.json` (Claude Code's user settings). This key was added:

```json
"statusLine": {
  "type": "command",
  "command": "bash /home/steamos/.claude/statusline-command.sh"
}
```

The existing keys `modelSettings`, `theme` and `tui` were left unchanged. Before this change, the file had only those three keys.

## Verified

The script was fed sample input for each case:

| Case | Output |
|---|---|
| Non-git folder (`Frame/`) | `➜  Frame` |
| Clean repo | `➜  repo git:(main)` |
| Repo with changes | `➜  repo git:(main) ✗` |
| Detached HEAD | `➜  repo git:(bfbad91) ✗` |
| Malformed input | falls back to the current folder (`➜  Frame`) |

Run time: about 50 ms.

## Customizing

Ask Claude to adjust it (for example: show the model name, context usage, or the Python venv). You can also edit `~/.claude/statusline-command.sh` directly.

## How to revert

```bash
rm ~/.claude/statusline-command.sh
# and delete the "statusLine": { … } block from ~/.claude/settings.json
```
