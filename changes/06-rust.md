# 06 — Rust toolchain (rustup)

- **Date:** 2026-10-12
- **Status:** Active
- **Version installed:** rustup 1.29.1, Rust stable 1.99.0 (`stable-aarch64-unknown-linux-gnu`)
- **Needs sudo:** No
- **Survives OS updates:** Yes (everything lives in the home folder). Linking relies on the system's C compiler (see Caveat).

## Why this way

rustup is the official Rust installer and version manager, the Rust equivalent of what uv does for Python. It installs into your home folder and handles updates, multiple toolchains, and extra components. SteamOS's `pacman` Rust would be wiped on every OS update.

## Everyday use

```bash
cargo new myapp && cd myapp      # new project
cargo run                         # build + run
cargo clippy                      # lint
cargo fmt                         # format
rustup update                     # update Rust (and rustup itself)
rustup component add rust-docs    # optional offline docs (skipped to save ~several hundred MB)
rustup doc                        # open them (after adding rust-docs)
```

For VS Code, install the **rust-analyzer** extension. It uses the `rust-src` component installed here.

## Changes made

### Installer verification

- `rustup-init` 1.29.1 for `aarch64-unknown-linux-gnu`, downloaded from `static.rust-lang.org`.
- SHA-256 `15f6e4ce9f583b929c996c91562bad6d4454f3281de858b02cdfdef615fac433`, matching the published `rustup-init.sha256`.
- Run as:
  ```bash
  rustup-init -y --no-modify-path --default-toolchain stable --profile minimal -c rustfmt -c clippy -c rust-src
  ```
  The `minimal` profile skips the offline docs. `--no-modify-path` stops rustup from editing shell files; the PATH line was added by hand instead (below).
- Note: rustup-init 1.29.1 prints a few stray build-debug lines (`CC = None`, `cargo:rerun-if-env-changed=…`) during install. We confirmed it does this even when installing nothing (`--default-toolchain none` into a throwaway location), so it's cosmetic and nothing is compiled.

### Files created

| Path | Purpose |
|---|---|
| `~/.rustup/` (~600 MB) | Toolchains and components |
| `~/.cargo/bin/` | `rustup`, `cargo`, `rustc`, `rustfmt`, `clippy`, etc. These are small launchers that run the active toolchain. |
| `~/.cargo/env` | Script that adds `~/.cargo/bin` to PATH |
| `~/.cargo/registry/` (later) | Downloaded crates (cache) |

Components installed: `cargo`, `clippy`, `rust-src`, `rust-std`, `rustc`, `rustfmt`.

### Settings modified

`~/.bashrc` got this block. The file as it was after change 05 is saved at [`backups/05/bashrc.after-uv`](../backups/05/bashrc.after-uv).

```bash
# Rust (rustup/cargo) on PATH + tab completion (Works/Frame change 06)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
if command -v rustup >/dev/null; then
  eval "$(rustup completions bash rustup)"
  eval "$(rustup completions bash cargo)"
fi
```

VS Code, even when opened from the app launcher, reads your shell's environment, so it sees this PATH too.

## Verified

- `rustc 1.99.0`, `cargo 1.99.0`; `rustup show` reports `stable-aarch64-unknown-linux-gnu` as the default.
- Throwaway project: `cargo new` → `cargo run` printed "Hello, world!". `cargo clippy` and `cargo fmt --check` both passed.
- Tab completion registered for `rustup` and `cargo`.

## Caveat

Rust uses the system's C compiler and linker (`/usr/bin/cc`) to produce programs. That compiler is part of the read-only SteamOS system. It's there today, but if a SteamOS update ever removed it, builds would fail at the linking step even though `~/.rustup` is intact. The fix then would be a container (podman is already installed) or a linker installed in the home folder.

## How to revert

```bash
rustup self uninstall      # removes ~/.rustup and ~/.cargo
# Then remove the "Rust (rustup/cargo)" block from ~/.bashrc,
# or restore: cp ~/Works/Frame/backups/05/bashrc.after-uv ~/.bashrc
```
