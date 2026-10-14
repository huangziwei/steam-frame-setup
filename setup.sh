#!/usr/bin/env bash
# setup.sh — set up a Steam Frame like the first one (changes/01–16 in this repo).
#
# Usage: ./setup.sh             run every step (safe to re-run: finished steps are skipped)
#        ./setup.sh STEP...     run only these steps, e.g. ./setup.sh vscode keyboard
#        ./setup.sh --list      list the steps
#        ./setup.sh --diff      show where this device's files differ from home/
#        ./setup.sh --collect   copy this device's files into home/ (after changing them here)
#
# Files in home/ are copied into ~, with /home/steamos replaced by $HOME. An existing file with
# different content is backed up first, to ~/.local/state/frame-setup/backup-<date-time>/.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_FILES="$REPO/home"
BACKUP="$HOME/.local/state/frame-setup/backup-$(date +%Y%m%d-%H%M%S)"
BREW=/home/linuxbrew/.linuxbrew/bin/brew

GIT_NAME="huangziwei"
GIT_EMAIL="huang-ziwei@outlook.com"
GITHUB_USER="huangziwei"
FRAME_REPO_SSH="git@github.com:huangziwei/steam-frame-setup.git"
CLAUDE_USAGE_REPO="git@github.com:huangziwei/claude-usage.git"
XREMAP_VERSION="0.15.14"
XREMAP_ZIP_SHA256="44374eec093380afab024c656ca430145450ea155153626e306fd65d6240bbee"
# https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
GITHUB_ED25519_FP="SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU"

STEPS=(sudo homebrew git shell konsole uv rust vscode keyboard desktop claude github claude-usage tailscale mac-screen)
declare -A ABOUT=(
  [sudo]="set a password for sudo if needed (only for installing Homebrew)"
  [homebrew]="Homebrew (07)"
  [git]="git from Homebrew + name/email (12)"
  [shell]="zsh + Oh My Zsh, ~/.bashrc ~/.zshrc ~/.inputrc (05–08)"
  [konsole]="Konsole opens zsh (08)"
  [uv]="uv + newest Python (05)"
  [rust]="Rust via rustup (06)"
  [vscode]="VS Code + code-update, launchers, settings (no built-in AI), Mac keys (03, 08, 11, 14)"
  [keyboard]="Mac keys: xremap in Desktop Mode, Cmd=Ctrl in Game Mode, Cmd+Tab (01, 02, 11)"
  [desktop]="Desktop Mode at 1920×1080, no black bars (04)"
  [claude]="Claude Code + its settings, no VS Code extension auto-install (10, 14)"
  [github]="SSH key for GitHub (12) — asks you to paste the key on github.com"
  [claude-usage]="claude-usage status line + reports (10)"
  [tailscale]="Tailscale: reach this Frame by name from the Mac (15) — asks for a name, sign-in link"
  [mac-screen]="Remmina + the mac command: the Mac's screen in a window (16) — ~1.5 GB download"
)

bold=$'\e[1m' green=$'\e[32m' yellow=$'\e[33m' red=$'\e[31m' reset=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$bold" "$*" "$reset"; }
ok()   { printf '  %s✓%s %s\n' "$green" "$reset" "$*"; }
warn() { printf '  %s!%s %s\n' "$yellow" "$reset" "$*"; }
die()  { printf '%s✗ %s%s\n' "$red" "$*" "$reset" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
ask()  { local a; read -r -p "  $1 " a </dev/tty; printf '%s' "$a"; }
MANUAL=()   # things only you can do, listed at the end

load_paths() {   # same PATH order as ~/.bashrc: ~/.cargo/bin > ~/.local/bin > Homebrew > system
  if [[ -x $BREW ]]; then eval "$("$BREW" shellenv bash)"; fi
  export PATH="$HOME/.local/bin:$PATH"
  if [[ -f $HOME/.cargo/env ]]; then . "$HOME/.cargo/env"; fi
  hash -r
}
need_brew() { [[ -x $BREW ]] || die "Homebrew is missing — run: ./setup.sh sudo homebrew"; load_paths; }
brew_install() { brew list "$1" >/dev/null 2>&1 || brew install "$1"; }

# install_file REL: copy home/REL to ~/REL (keeping its permissions), backing up a different existing file
install_file() {
  local rel=$1 src="$HOME_FILES/$1" dst="$HOME/$1" tmp note=""
  tmp=$(mktemp)
  sed "s|/home/steamos|$HOME|g" "$src" >"$tmp"
  if [[ -f $dst ]] && cmp -s "$tmp" "$dst"; then rm "$tmp"; ok "~/$rel (already up to date)"; return; fi
  if [[ -e $dst ]]; then
    mkdir -p "$BACKUP/$(dirname "$rel")" && cp -p "$dst" "$BACKUP/$rel"
    note=" (old version backed up)"
  fi
  mkdir -p "$(dirname "$dst")"
  install -m "$(stat -c %a "$src")" "$tmp" "$dst" && rm "$tmp"
  ok "~/$rel$note"
}

github_ok() {
  local out
  out=$(ssh -T -o BatchMode=yes -o ConnectTimeout=10 git@github.com 2>&1 || true)
  [[ $out == *"Hi $GITHUB_USER!"* ]]
}

# ------------------------------------------------------------------------------------- steps

step_sudo() {
  step "Admin password (sudo), needed once for installing Homebrew"
  if [[ -x $BREW ]]; then ok "Homebrew is already installed, so sudo isn't needed"; return; fi
  if sudo -n true 2>/dev/null; then ok "sudo works"; return; fi
  local a; a=$(ask "Have you already set a password for '$USER' (with passwd)? [y/N]")
  if [[ $a != [yY]* ]]; then
    echo "  Choose a password for '$USER'. It becomes your sudo password."
    passwd </dev/tty
  fi
  sudo -v </dev/tty || die "sudo didn't accept the password"
  ok "sudo works"
}

step_homebrew() {
  step "Homebrew (changes/07)"
  if [[ ! -x $BREW ]]; then
    sudo -v </dev/tty   # Homebrew's installer needs sudo once, to create /home/linuxbrew
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  load_paths
  ok "$(brew --version | sed -n 1p)"
}

step_git() {
  step "git + identity (changes/12)"
  need_brew
  brew_install git
  hash -r
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  git config --global init.defaultBranch main
  ok "$(git --version) as $GIT_NAME <$GIT_EMAIL>"
}

step_shell() {
  step "zsh + Oh My Zsh + shell files (changes/05–08)"
  need_brew
  brew_install zsh
  install_file .bashrc
  install_file .zshrc
  install_file .inputrc
  if [[ ! -d $HOME/.oh-my-zsh ]]; then
    # No login-shell change, don't start zsh, keep our ~/.zshrc
    ZSH="$HOME/.oh-my-zsh" RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
  ok "Oh My Zsh in ~/.oh-my-zsh"
}

step_konsole() {
  step "Konsole opens zsh (changes/08)"
  install_file .local/share/konsole/Zsh.profile
  kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile Zsh.profile
  ok "default Konsole profile: Zsh"
}

step_uv() {
  step "uv + Python (changes/05)"
  load_paths
  if ! have uv; then curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh; fi
  load_paths
  (cd "$HOME" && uv python install)   # newest Python; plain python3 stays SteamOS's own
  ok "$(uv --version), $(uv python find 2>/dev/null)"
}

step_rust() {
  step "Rust via rustup (changes/06)"
  if [[ ! -x $HOME/.cargo/bin/rustup ]]; then
    local t url
    t=$(mktemp -d)
    url="https://static.rust-lang.org/rustup/dist/$(uname -m)-unknown-linux-gnu/rustup-init"
    curl -fsSL -o "$t/rustup-init" "$url"
    curl -fsSL -o "$t/rustup-init.sha256" "$url.sha256"
    [[ $(sha256sum "$t/rustup-init" | cut -d' ' -f1) == "$(cut -d' ' -f1 "$t/rustup-init.sha256")" ]] \
      || die "rustup-init checksum mismatch"
    chmod +x "$t/rustup-init"
    "$t/rustup-init" -y --no-modify-path --default-toolchain stable --profile minimal -c rustfmt -c clippy -c rust-src
    rm -rf "$t"
  fi
  load_paths
  ok "$(rustc --version)"
}

step_vscode() {
  step "VS Code (changes/03, 08, 11)"
  install_file .local/bin/code-update
  load_paths
  code-update || warn "code-update failed (is VS Code open? quit it and run: ./setup.sh vscode)"
  ln -sfn "$HOME/.local/opt/vscode/bin/code" "$HOME/.local/bin/code"
  install_file .local/share/applications/code.desktop
  install_file .local/share/applications/code-url-handler.desktop
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  kbuildsycoca6 >/dev/null 2>&1 || true
  xdg-mime default code-url-handler.desktop x-scheme-handler/vscode
  install_file .config/Code/User/settings.json
  install_file .config/Code/User/keybindings.json
  # Claude Code runs in the integrated terminal only, so no Claude extension (change 14)
  local exts; exts=$(code --list-extensions 2>/dev/null || true)
  if [[ $'\n'$exts$'\n' == *$'\nanthropic.claude-code\n'* ]]; then code --uninstall-extension anthropic.claude-code; fi
  ok "VS Code $(code --version | sed -n 1p), built-in AI off"
}

step_keyboard() {
  step "Mac-style keys (changes/01, 02, 11)"
  [[ " $(id -nG) " == *" input "* ]] || warn "'$USER' isn't in the 'input' group, so xremap can't read keyboards"
  if [[ "$("$HOME/.local/bin/xremap" --version 2>/dev/null || true)" != "xremap $XREMAP_VERSION" ]]; then
    local t; t=$(mktemp -d)
    curl -fsSL -o "$t/xremap.zip" \
      "https://github.com/xremap/xremap/releases/download/v$XREMAP_VERSION/xremap-linux-$(uname -m)-kde.zip"
    echo "$XREMAP_ZIP_SHA256  $t/xremap.zip" | sha256sum -c --quiet || die "xremap checksum mismatch"
    unzip -q -o "$t/xremap.zip" -d "$t"
    mkdir -p "$HOME/.local/bin" && install -m 755 "$t/xremap" "$HOME/.local/bin/xremap"
    rm -rf "$t"
  fi
  ok "xremap $XREMAP_VERSION"
  install_file .config/xremap/config.yml
  install_file .config/systemd/user/xremap.service
  install_file .local/bin/mac-keys-gamemode
  install_file .config/systemd/user/mac-keys-gamemode.service
  systemctl --user daemon-reload
  systemctl --user enable xremap.service mac-keys-gamemode.service 2>/dev/null
  # Start whichever one belongs to the mode we're in now
  if systemctl --user -q is-active plasma-workspace.target; then systemctl --user restart xremap.service; fi
  if systemctl --user -q is-active gamescope-session.target; then systemctl --user restart mac-keys-gamemode.service; fi
  ok "xremap runs in Desktop Mode, mac-keys-gamemode in Game Mode"
  # Desktop Mode: Cmd+Tab arrives as Ctrl+Tab, so the window switcher listens to it too
  kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Walk Through Windows" \
    $'Alt+Tab\tCtrl+Tab,Alt+Tab,Walk Through Windows'
  kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Walk Through Windows (Reverse)" \
    $'Alt+Shift+Tab\tCtrl+Shift+Tab,Alt+Shift+Tab,Walk Through Windows (Reverse)'
  ok "Cmd+Tab switches windows in Desktop Mode (from the next Desktop Mode start)"
  MANUAL+=("Pair the Pebble over Bluetooth, then hold Fn+O for 3 s to put it in macOS mode")
}

step_desktop() {
  step "Desktop Mode resolution (changes/04)"
  install_file .config/systemd/user/plasma-kwin_wayland.service.d/desktop-resolution.conf
  systemctl --user daemon-reload
  ok "applies the next time Desktop Mode starts"
}

step_claude() {
  step "Claude Code (changes/10)"
  load_paths
  if ! have claude; then curl -fsSL https://claude.ai/install.sh | bash; fi
  load_paths
  local dst="$HOME/.claude/settings.json" tmp
  tmp=$(mktemp)
  # statusLine and env vars always come from home/; other keys (theme, effort…) only fill in what's missing
  python3 -I - "$HOME_FILES/.claude/settings.json" "$dst" "$HOME" >"$tmp" <<'EOF'
import json, os, sys
src, dst, home = sys.argv[1:]
want = json.loads(open(src).read().replace("/home/steamos", home))
cur = json.load(open(dst)) if os.path.exists(dst) else {}
env = {**cur.get("env", {}), **want.get("env", {})}
print(json.dumps({**want, **cur, "statusLine": want["statusLine"], "env": env}, indent=2))
EOF
  if [[ -f $dst ]] && cmp -s "$tmp" "$dst"; then
    rm "$tmp"
  else
    if [[ -f $dst ]]; then mkdir -p "$BACKUP/.claude" && cp -p "$dst" "$BACKUP/.claude/settings.json"; fi
    mkdir -p "$HOME/.claude" && install -m 644 "$tmp" "$dst" && rm "$tmp"
  fi
  ok "$(claude --version 2>/dev/null | sed -n 1p), settings in ~/.claude/settings.json"
  MANUAL+=("Sign in to Claude Code: run claude")
}

step_github() {
  step "SSH key for GitHub (changes/12)"
  local key="$HOME/.ssh/id_ed25519" t a
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  if ! ssh-keygen -F github.com >/dev/null 2>&1; then
    t=$(mktemp)
    ssh-keyscan -t ed25519 github.com 2>/dev/null >"$t"
    [[ $(ssh-keygen -lf "$t" | awk '{print $2}') == "$GITHUB_ED25519_FP" ]] \
      || die "GitHub's host key doesn't match the fingerprint GitHub publishes. Not trusting it."
    cat "$t" >>"$HOME/.ssh/known_hosts" && rm "$t"
    ok "GitHub's host key verified and saved"
  fi
  if [[ ! -f $key ]]; then
    ssh-keygen -t ed25519 -C "$GIT_EMAIL (Steam Frame, set up $(date +%F))" -f "$key" -N "" -q
    ok "new key ~/.ssh/id_ed25519 (no passphrase)"
  fi
  if github_ok; then ok "GitHub already accepts this key"; else
    printf '\n  Add this public key to GitHub (it is one line):\n\n%s\n\n' "$(cat "$key.pub")"
    echo "  1. Open https://github.com/settings/ssh/new"
    echo "  2. Title: Steam Frame $(date +%F) · Key type: Authentication Key · paste the key · Add SSH key"
    if have code; then
      code "$key.pub" >/dev/null 2>&1 || true
      echo "     The key is also open in VS Code: click into it, Cmd+A, Cmd+C."
    fi
    while ! github_ok; do
      a=$(ask "Press Enter once the key is added (s = skip for now):")
      if [[ $a == [sS]* ]]; then
        warn "skipped"
        MANUAL+=("Add ~/.ssh/id_ed25519.pub on GitHub, then run: ./setup.sh github claude-usage")
        return
      fi
    done
    ok "GitHub says hi to $GITHUB_USER"
  fi
  # This repo was cloned over HTTPS by bootstrap.sh; switch to SSH so pushing works
  if [[ -d $REPO/.git && "$(git -C "$REPO" remote get-url origin 2>/dev/null)" == https://github.com/* ]]; then
    git -C "$REPO" remote set-url origin "$FRAME_REPO_SSH"
    ok "this repo now pushes over SSH"
  fi
}

step_claude-usage() {
  step "claude-usage status line (changes/10)"
  load_paths
  if ! github_ok; then
    warn "needs the GitHub SSH key first, skipping"
    return
  fi
  local dir="$HOME/Works/claude-usage"
  [[ -d $dir/.git ]] || git clone "$CLAUDE_USAGE_REPO" "$dir"
  local tools; tools=$(uv tool list 2>/dev/null || true)
  [[ $tools == *claude-usage* ]] || uv tool install --editable "$dir"
  ok "claude-usage and claude-statusline in ~/.local/bin"
}

step_tailscale() {
  step "Tailscale (changes/15)"
  install_file .local/bin/tailscale-update
  local ts=/var/opt/tailscale/tailscale name=""
  if [[ $("$ts" status --json 2>/dev/null | python3 -I -c 'import json,sys; print(json.load(sys.stdin).get("BackendState",""))' 2>/dev/null) != Running ]]; then
    name=$(ask "Name for this Frame on Tailscale (the first one is 'frame') [frame2]:")
    name=${name:-frame2}
  fi
  "$HOME/.local/bin/tailscale-update" ${name:+--hostname "$name"}
  MANUAL+=("Tailscale admin (login.tailscale.com → Machines → this Frame → ⋯): Disable key expiry")
}

step_mac-screen() {
  step "Mac screen in a window: Remmina (changes/16)"
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  if ! flatpak info --user org.remmina.Remmina >/dev/null 2>&1; then
    echo "  Downloading Remmina and the GNOME runtime it needs: about 1.5 GB, often 10+ minutes."
    flatpak install --user --noninteractive -y flathub org.remmina.Remmina
  fi
  ok "Remmina $(flatpak info --user org.remmina.Remmina | awk '/Version:/ {print $2}')"
  install_file .local/bin/mac
  MANUAL+=("On the Mac: System Settings → General → Sharing → Screen Sharing on (only your user); then run: mac")
}

# ------------------------------------------------------------------------------------- modes

list_files() { (cd "$HOME_FILES" && find . -type f -printf '%P\n' | sort); }

diff_mode() {
  local rel n=0
  while IFS= read -r rel; do
    if [[ ! -e $HOME/$rel ]]; then echo "missing on this device: ~/$rel"; n=$((n + 1)); continue; fi
    sed "s|/home/steamos|$HOME|g" "$HOME_FILES/$rel" \
      | diff -u --label "home/$rel (repo)" --label "~/$rel (device)" - "$HOME/$rel" || n=$((n + 1))
  done < <(list_files)
  ((n == 0)) && echo "All $(list_files | wc -l) files match." || echo "$n file(s) differ."
}

collect_mode() {
  local rel
  while IFS= read -r rel; do
    [[ -e $HOME/$rel ]] || continue
    sed "s|$HOME|/home/steamos|g" "$HOME/$rel" >"$HOME_FILES/$rel"   # > keeps the file's mode
  done < <(list_files)
  git -C "$REPO" status --short -- home/
}

main() {
  case "${1:-}" in
    --list)    for s in "${STEPS[@]}"; do printf '  %-13s %s\n' "$s" "${ABOUT[$s]}"; done; return ;;
    --diff)    diff_mode; return ;;
    --collect) collect_mode; return ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; return ;;
  esac
  [[ $EUID -ne 0 ]] || die "Run this as your normal user, not with sudo."
  [[ $(uname -m) == aarch64 ]] || warn "This was made for the Steam Frame (aarch64); this machine is $(uname -m)."

  local run=("$@") s
  ((${#run[@]})) || run=("${STEPS[@]}")
  for s in "${run[@]}"; do [[ -n ${ABOUT[$s]:-} ]] || die "Unknown step '$s'. See ./setup.sh --list"; done
  for s in "${run[@]}"; do "step_$s"; done

  step "Done"
  [[ -d $BACKUP ]] && echo "  Files that were replaced are backed up in $BACKUP"
  if ((${#MANUAL[@]})); then
    echo "  Left for you:"
    for s in "${MANUAL[@]}"; do echo "    • $s"; done
  fi
  echo "  Open a new terminal to get zsh with everything on PATH."
}

main "$@"
