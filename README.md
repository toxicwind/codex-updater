<div align="center">

# Codex Updater ♻️

Make the OpenAI Codex CLI your own without playing tag with upstream releases.

<a href="LICENSE"><img src="https://img.shields.io/badge/license-WTFPL-magenta.svg" alt="License"></a>
<a href="https://github.com/toxicwind/codex-updater/actions/workflows/ci.yml"><img src="https://github.com/toxicwind/codex-updater/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
<a href="https://github.com/toxicwind/codex-updater/releases/latest"><img src="https://img.shields.io/github/v/release/toxicwind/codex-updater?label=latest" alt="Release"></a>

</div>

**Codex Updater** is a cross-distro toolkit that vendors the upstream **OpenAI Codex** repo, applies community/private patches, builds a versioned CLI, and installs it to a user prefix. It ships a wrapper that adds auto-updates, logging, and commit-aware caching so you only rebuild when upstream actually changes.

## What’s new (patching model)

- **Vendored upstream** at `vendor/codex` (git submodule)
- **Community patches** at `patches/community` (git submodule → [`toxicwind/codex-patches`](https://github.com/toxicwind/codex-patches))
- **Local patches** at `patches/local` (ignored; your private queue)
- **Idempotent scripts** to apply, create, and promote patches:
  - `scripts/patch-apply.sh` — apply community + local (auto-detects CLI root, remaps paths)
  - `scripts/patch-new.sh "subject"` — capture staged changes into `patches/local/000N-*.patch`
  - `scripts/patch-export.sh <local-patch>` — promote to `patches/community` and push

## Features

- Commit-aware caching: rebuilds only when upstream or patches change  
- Tag-/commit-aware versions: `codex --version` surfaces Git tags when available, otherwise `<YYYY.MMDD.HHMM+sha>` so you know exactly which upstream commit is installed  
- Cross-distro bootstrap (apt, dnf/dnf5/yum, pacman, zypper, apk, Linuxbrew)  
- Wrapper UX: on-demand updates, background auto-update, and logs with build info  
- **Multi-OS CI**: patch + build + smoke tests on Linux and macOS across Node LTSes  

## Requirements

- Linux or WSL; macOS supported via CI and local builds  
- Rust toolchain (installed automatically via `rustup` if missing)  
- OpenSSL dev headers (installed when possible)  
- Node.js (for upstream CLI build; CI tests Node 18/20/22)  

## Install

```bash
chmod +x codex codex-updater
mkdir -p ~/.local/bin-core
cp codex codex-updater ~/.local/bin-core/

codex --wrapper-update
codex --wrapper-version
```

> **Note:** The wrapper aliases `codex` → `codex-updater`. It performs a background auto-update based on the 24 h interval, but it no longer forces a rebuild on every single invocation. Export `CODEX_WRAPPER_ALWAYS_UPDATE=1` if you want a pre-flight rebuild before each launch.

## Configuration

Wrapper env:

* `CODEX_UPDATER` — override updater path (default: `~/.local/bin-core/codex-updater`)
* `CODEX_BIN` — override installed binary (default: `~/.local/bin/codex`)
* `CODEX_WRAPPER_AUTO_UPDATE=0` — disable the 24 h background auto-update (default is on)
* `CODEX_WRAPPER_AUTO_INTERVAL` — seconds between checks (default: `86400`)
* `CODEX_WRAPPER_ALWAYS_UPDATE` — force the updater before every launch (default `0`, set `1` to opt in)
* `CODEX_WRAPPER_ALLOW_SUDO=1` — opt back into package-manager installs (wrapper defaults to `--no-sudo`)
* `CODEX_WORKSPACE` — path to a local `codex-updater` checkout to mirror (auto-detects `~/development/codex-updater`)
* `CODEX_WORKSPACE_SYNC=1` — git fetch + `scripts/patch-apply.sh` on that workspace before building (default `0`)

Updater flags:

* `--prefix DIR`, `--branch NAME`, `--repo URL`, `--no-sudo`, `--force-rebuild`, `--cc/--cxx`
* `--opt-preset portable|balanced|native` — portable keeps upstream defaults, balanced enables ThinLTO/codegen-units 4 (default), native adds `-C target-cpu=native` + panic=abort
* `--cpu-target <rustc-target>` — force a specific `-C target-cpu` (overrides preset)
* `--sccache-mode on|off|auto` — pick how aggressively to use `sccache` as the `RUSTC_WRAPPER`
* `--workspace DIR` — build from an existing checkout (mirrored into `~/.cache/codex-workspace-build`)
* `--skip-deps` — skip dependency installation (same as `CODEX_SKIP_BUILD_DEPS=1`)

Related env knobs mirror the flags: `CODEX_OPT_PRESET`, `CODEX_TARGET_CPU`, `CODEX_USE_SCCACHE`, `CODEX_EXTRA_RUSTFLAGS`, `CODEX_CARGO_JOBS`, `CODEX_WORKSPACE`, `CODEX_WORKSPACE_SYNC`, and `CODEX_SKIP_BUILD_DEPS`.

## Repo layout

```
.
├─ codex                 # lightweight wrapper (delegates, updates, logs)
├─ codex-updater         # builder/installer for upstream codex
├─ vendor/
│  └─ codex              # upstream submodule (openai/codex)
├─ patches/
│  ├─ community          # submodule → toxicwind/codex-patches
│  └─ local              # your private patches (gitignored)
└─ scripts/
   ├─ patch-apply.sh     # apply community + local patches
   ├─ patch-new.sh       # create a new local patch from staged changes
   ├─ patch-export.sh    # promote local → community and push
   └─ codex-build.sh     # build & smoke-test the CLI
```

## Typical workflow

```bash
# 0) Make sure submodules are present
git submodule update --init --recursive

# 1) Apply patches (community + local) onto upstream
./scripts/patch-apply.sh

# 2) Build upstream CLI and run quick smoke tests
./scripts/codex-build.sh

# 3) Make a change inside vendor/codex (CLI)
( cd vendor/codex && $EDITOR codex-cli/src/sessions.ts && git add -A )

# 4) Capture your change as a patch
./scripts/patch-new.sh "feat(cli/sessions): add --json and --limit flags"

# 5) Test the patch again from a clean state
git -C vendor/codex reset --hard HEAD~1
./scripts/patch-apply.sh && ./scripts/codex-build.sh

# 6) Promote your patch to the public community repo
./scripts/patch-export.sh patches/local/0001-feat-cli-sessions-add-json-and-limit.patch
```

## Packager CLI

`scripts/packager.sh` wraps the common chores so you don't need a Makefile:

```bash
# format in place (shfmt -w -i 2 -ci)
./scripts/packager.sh fmt

# lint with shellcheck -S style
./scripts/packager.sh lint

# run both (writes formatting first)
./scripts/packager.sh check
```

## Git hooks

Enable the bundled hook path once per clone:

```bash
git config core.hooksPath .githooks
```

The `pre-commit` hook runs `packager fmt` (writes) followed by `packager lint`.  
If formatting makes changes, the commit aborts so you can stage the updated files.

## CI

The CI builds on Linux and macOS, across Node 18/20/22, and uploads built `dist/` artifacts for inspection.

```yaml
# .github/workflows/patch-check.yml
name: Patch & Build Codex
on:
  push: { branches: ["**"] }
  pull_request: { branches: ["**"] }
jobs:
  patch-and-build:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
        node: [18, 20, 22]
    steps:
      - uses: actions/checkout@v4
        with: { submodules: true }
      - uses: actions/setup-node@v4
        with: { node-version: ${{ matrix.node }} }
      - name: Apply patches
        run: ./scripts/patch-apply.sh
      - name: Build & smoke-test
        run: ./scripts/codex-build.sh
      - name: Upload dist
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: codex-dist-${{ matrix.os }}-node${{ matrix.node }}
          path: vendor/codex/**/dist
          if-no-files-found: ignore
```

## How it works

1. **Updater** detects the current upstream commit + patchset hash and builds only when that **tuple changes**.
2. **Patches** are applied with `git am` in order: community → local.
3. **Build** uses the upstream package manager (`pnpm` or `npm`); **wrapper** registers build metadata.
4. **Wrapper** can trigger on-demand update or run on an interval (opt-in env var).

## Development

* `./scripts/packager.sh check` runs `shfmt` (writes) then `shellcheck`
* `./scripts/packager.sh fmt-check` shows diffs without rewriting
* Keep scripts POSIX-friendly; avoid hard distro assumptions
* Patches should be targeted, reviewable, and rebased as needed

## Security & License

* Private reporting: see `SECURITY.md`
* License: WTFPL v2 (see `LICENSE`)
