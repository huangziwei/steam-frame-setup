#!/usr/bin/env bash
# bootstrap.sh — first step on a brand-new Steam Frame. In Konsole, run:
#
#   curl -fsSL https://raw.githubusercontent.com/huangziwei/steam-frame-setup/main/bootstrap.sh | bash
#
# It downloads this repo to ~/Works/Frame (over HTTPS; setup.sh switches it to SSH once your
# GitHub key works) and starts ./setup.sh, which runs every step.
set -euo pipefail

DIR="$HOME/Works/Frame"
if [[ -d $DIR/.git ]]; then
  git -C "$DIR" pull --ff-only
else
  mkdir -p "$(dirname "$DIR")"
  git clone https://github.com/huangziwei/steam-frame-setup.git "$DIR"
fi
cd "$DIR"
exec ./setup.sh "$@" </dev/tty   # stdin is the curl pipe; questions must come from the keyboard
