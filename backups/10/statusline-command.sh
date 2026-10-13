#!/bin/bash
# Mirrors the Oh My Zsh robbyrussell prompt: ➜  dir git:(branch) ✗
# jq may be absent, so parse stdin with python3.
cwd=$(python3 -I -c 'import sys,json
try:
    d=json.load(sys.stdin)
    print(d.get("workspace",{}).get("current_dir") or d.get("cwd") or "")
except Exception:
    print("")')
[ -z "$cwd" ] && cwd=$PWD
dir=$(basename "$cwd")

out=$(printf '\033[1;32m➜\033[0m  \033[36m%s\033[0m' "$dir")

branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null \
  || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  out="$out $(printf '\033[1;34mgit:(\033[31m%s\033[34m)\033[0m' "$branch")"
  if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -n1)" ]; then
    out="$out $(printf '\033[33m✗\033[0m')"
  fi
fi
printf '%s\n' "$out"
