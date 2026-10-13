# 12 — git 2.56 (Homebrew) + GitHub over SSH

- **Date:** 2026-10-13
- **Status:** Active
- **Needs sudo:** No
- **Survives OS updates:** Yes (Homebrew and `~/.ssh` live outside the system part of SteamOS)

## Why

To use git and GitHub (`huangziwei`) from the Frame. SteamOS includes git 2.44 at `/usr/bin/git`. Homebrew's 2.56 is newer and comes before it on the PATH, following the "command-line tools via Homebrew" rule from [07](07-homebrew.md).

## Changes made

### Installed

| What | How |
|---|---|
| git 2.56.0 | `brew install git` → `/home/linuxbrew/.linuxbrew/bin/git`. `/usr/bin/git` (2.44) is untouched; apps that don't use the shell PATH, such as VS Code launched from Steam, may still use it. Both read the same `~/.gitconfig`. |

### Files created (none existed before)

| File | Contents |
|---|---|
| `~/.gitconfig` | `user.name = huangziwei`, `user.email = huang-ziwei@outlook.com`, `init.defaultBranch = main` |
| `~/.ssh/id_ed25519` | Private SSH key (ed25519, **no passphrase**). Never share this file. |
| `~/.ssh/id_ed25519.pub` | Public key, comment `huang-ziwei@outlook.com (Steam Frame)`. This is the part that goes on GitHub. |
| `~/.ssh/known_hosts` | GitHub's ed25519 host key, `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`. Checked against [GitHub's published fingerprints](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints). |

**No passphrase:** anyone who gets a copy of `~/.ssh/id_ed25519` can push as you until the key is removed on GitHub. On macOS the Keychain usually remembers a key's passphrase, but there is no keychain running in Game Mode, so a passphrase would have to be typed on every push. To add one later: `ssh-keygen -p -f ~/.ssh/id_ed25519`.

## Adding the key to GitHub

1. Copy the public key, which is one line starting with `ssh-ed25519`. `code ~/.ssh/id_ed25519.pub` opens it in VS Code, where Cmd+A, Cmd+C works.
2. Go to <https://github.com/settings/ssh/new> (Settings → SSH and GPG keys → New SSH key).
3. Title: `Steam Frame`. Key type: **Authentication Key**. Paste the key and click **Add SSH key**.
4. Test it: `ssh -T git@github.com`. It should answer `Hi huangziwei! You've successfully authenticated…`

Then use SSH URLs: `git clone git@github.com:huangziwei/<repo>.git`.

## How to revert

```bash
# 1. On GitHub: Settings → SSH and GPG keys → delete "Steam Frame"
# 2. Remove the key, GitHub's host key entry, and the git config
rm ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
ssh-keygen -R github.com
rm ~/.gitconfig
# 3. Remove Homebrew git (falls back to SteamOS's /usr/bin/git 2.44)
brew uninstall git
```

## Open items

- [x] Key added on GitHub as "Steam Frame". `ssh -T git@github.com` greeted `huangziwei` on 2026-10-13.
