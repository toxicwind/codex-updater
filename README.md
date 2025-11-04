<div align="center">

# Codex Updater ♻️

**Make the OpenAI Codex CLI your own without playing tag with upstream releases.**

[![License: WTFPL](https://img.shields.io/badge/license-WTFPL-magenta.svg)](LICENSE)
[![CI](https://github.com/toxicwind/codex-updater/actions/workflows/ci.yml/badge.svg)](https://github.com/toxicwind/codex-updater/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/toxicwind/codex-updater?label=latest)](https://github.com/toxicwind/codex-updater/releases/latest)

</div>

Out of the box, the Codex CLI ships as a monolithic binary—you pull the “latest”
release, drop it on PATH, and hope it was built the way you need. Tweaking the build
is painful: you burn time cloning repositories, wiring toolchains, and trying to
remember which commit you compiled last week.

**Codex Updater fixes that.** It is a self-contained toolkit that clones upstream,
tracks commits, injects the latest release tags, and installs a wrapper so you can
launch Codex like normal—while still owning the build pipeline.

## ✨ What you get

- **Commit-aware builds** – caches binaries per commit hash and skips rebuilds when upstream hasn’t moved.
- **Tag-aligned versions** – rewrites the workspace `Cargo.toml` to match the newest `rust-v*` tag so `codex --version` reflects reality.
- **First-on-PATH wrapper** – a drop-in `codex` shim with auto-update toggles, metadata output, and friendly logging.
- **Audit trail** – everything logs to `~/logs/codex-wrapper.log` and stores metadata in `~/.local/share/codex-wrapper/`.

## 📦 Repository layout

```
README.md          # this doc
codex-updater      # build + install script
codex              # wrapper shim (place before the real binary on PATH)
.github/           # CI and release workflows
```

## 🚀 Quickstart

```bash
git clone https://github.com/toxicwind/codex-updater.git
cd codex-updater

# Install into your helper bin
chmod +x codex codex-updater
mkdir -p ~/.local/bin-core
cp codex codex-updater ~/.local/bin-core/

# Build Codex locally (runs if binary missing or commit changed)
codex --wrapper-update

# Inspect build metadata
codex --wrapper-version
```

Prefer prebuilt artifacts? Download the tarball from the
[latest release](https://github.com/toxicwind/codex-updater/releases/latest) — it ships an LTO-optimized Linux amd64 Codex binary plus both scripts.

## 🛠 Wrapper flags & env knobs

| Flag | Description |
| --- | --- |
| `--wrapper-update` | Run the updater before launching `codex`. |
| `--wrapper-rebuild` | Force `cargo clean` + rebuild even if commit cached. |
| `--wrapper-no-update` | Skip auto-update for this invocation. |
| `--wrapper-version` | Print cached commit/version metadata and exit. |
| `--wrapper-print-target` | Show the delegated binary path. |

| Environment variable | Purpose | Default |
| --- | --- | --- |
| `CODEX_WRAPPER_AUTO_UPDATE` | Enable background auto-update checks | `0` |
| `CODEX_WRAPPER_AUTO_INTERVAL` | Seconds between auto-update checks | `86400` |
| `CODEX_UPDATER` | Override updater script path | `~/.local/bin-core/codex-updater` |
| `CODEX_BIN` | Override installed binary path | `~/.local/bin/codex` |

## 🧪 Automation

- **CI** (`ci.yml`): shfmt + shellcheck (+ bats if you add tests).
- **Release** (`release.yml`): archives `HEAD` and updates the `latest` tag with
  a fresh `codex-updater.tar.gz` artifact on every push to `main`.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs, issues, and discussions are open.
Run `make check` before submitting.

## 🔐 Security

Report vulnerabilities privately via the GitHub security advisory flow or
security@hypebrut.sh.

## 📜 License

Released under the [Do What The Fuck You Want To Public License](LICENSE).
It’s your build chain—bend it however you like.
