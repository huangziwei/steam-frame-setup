# 10 — Claude Code status line + usage tracking (`claude-usage`)

- **Date:** 2026-10-12
- **Status:** Active. Replaces [09](09-claude-statusline.md).
- **Code:** `~/Works/claude-usage` (uv project, 37 tests, not committed). Details are in its `README.md`.
- **Needs sudo:** No

## Why

Change 09 just copied the zsh prompt, which wasn't what you wanted. You pointed to your own tools as references:
- `huangziwei/dotclaude/statusline-command.py`: a status line that also logs session cost to `~/.claude/session-costs.csv`.
- `huangziwei/claude-costs`: a TUI that summarizes that CSV.

These are a new implementation of the same idea. It fixes these problems found in the originals:

1. Concurrent sessions read-modify-rewrite the same CSV with no locking, so updates get lost.
2. The whole CSV is rewritten and the whole transcript re-parsed on every refresh, so it gets slower over time.
3. Resume detection is a heuristic. It misfires when two sessions on one project overlap, which undercounts. It also only fixes cost, not tokens.
4. Days are bucketed in UTC, while sessions are displayed in local time (UTC+2 here).
5. A session's entire cost lands on the last-seen time, so sessions spanning midnight or a month boundary are misattributed.
6. An empty `cost_usd` value crashes the viewer (`float('')`).
7. Weekly labels use the ISO week of the Sunday, which is off by one.
8. The fallback uses `context_window.total_*_tokens`, which per the docs is the *current context*, not a session total.

## What it shows

```
Opus 5.5 high │ ctx ███░░░░░░░ 30% · 296k/1.0M │ $9.87 session · $11.80 today
~/Works/Frame · main* │ 5h 5% ↻21:50 · 7d 25% ↻Thu 10:00 │ +2494 −33
```

From left to right:
- model and effort
- context used, with a colored bar
- session cost and today's cost across all sessions
- folder, branch (with uncommitted changes and ahead/behind), and the open PR if there is one
- plan rate limits with reset times
- lines changed

Segments drop out automatically in narrow windows.

## Reports

```bash
claude-usage              # overview: today / yesterday / week / month / 30 days + by project
claude-usage daily        # also: weekly, monthly, sessions; --projects; --project TEXT
```

## Changes made

### Created

| Path | Purpose |
|---|---|
| `~/Works/claude-usage/` | Source, tests, README (uv project; `git init` by `uv init`, nothing committed) |
| `~/.local/share/uv/tools/claude-usage/` | Tool environment (`uv tool install --editable`) |
| `~/.local/bin/claude-statusline`, `~/.local/bin/claude-usage` | Commands (symlinks into the tool environment) |
| `~/.claude/usage/` | Data: `log/*.jsonl`, `state/*.json`, `last-input.json`, `errors.log` (only if errors occur) |

### Modified

`~/.claude/settings.json`, the `statusLine.command` value. The full previous file is saved at [`backups/10/claude-settings.json.before`](../backups/10/claude-settings.json.before).

| | Value |
|---|---|
| Before | `bash /home/steamos/.claude/statusline-command.sh` |
| After | `/home/steamos/.local/bin/claude-statusline` |

### Removed

`~/.claude/statusline-command.sh` (from change 09). A copy is saved at [`backups/10/statusline-command.sh`](../backups/10/statusline-command.sh).

## Verified

- `uv run pytest`: 37 passed. Tests cover baseline and resume handling, duplicate and cancelled writes, counter resets, midnight splits, locking, transcript repeats, partial lines, subagents, truncated transcripts, narrow terminals, and the report commands.
- Speed: 46–67 ms per status-line run.
- Tested against this session's real 2 MB transcript: token counts matched an independent recount exactly (input 2, cache write 1,672, cache read 289,639, output 714).
- The live status line is running with no `errors.log`. This session ($9.87 when first seen) is the baseline, so only usage from now on is counted.

## Limits

- Only sessions the status line sees are tracked. Earlier sessions and `claude -p` runs aren't.
- Costs are Claude Code's list-price estimates. On a subscription plan they're the API-equivalent value, not your bill.

## How to revert

```bash
# back to change 09's script (or restore the whole settings file)
cp ~/Works/Frame/backups/10/claude-settings.json.before ~/.claude/settings.json
cp ~/Works/Frame/backups/10/statusline-command.sh ~/.claude/statusline-command.sh

# remove the tool (keeps the source and data)
uv tool uninstall claude-usage

# also delete logged data / source
rm -rf ~/.claude/usage ~/Works/claude-usage
```

To remove the status line entirely, delete the `"statusLine"` block from `~/.claude/settings.json`.
