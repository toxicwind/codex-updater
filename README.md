<div align="center">

# Codex Updater ♻️

**Self-maintaining build + wrapper toolkit for the OpenAI Codex CLI.**

[![License: WTFPL](https://img.shields.io/badge/license-WTFPL-magenta.svg)](LICENSE)
[![CI](https://github.com/toxicwind/codex-updater/actions/workflows/ci.yml/badge.svg)](https://github.com/toxicwind/codex-updater/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/toxicwind/codex-updater?label=latest)](https://github.com/toxicwind/codex-updater/releases/latest)

</div>

Codex Updater is the home for the `codex` CLI wrapper and its build system. It keeps
track of upstream commits, stamps builds with real version tags, and leaves behind
logs + metadata so you can see exactly what runs in production.

## ✨ Highlights

- **Commit-aware builds** – reuse cached binaries when the upstream commit is unchanged.
- **Tag synchronized** – workspace `Cargo.toml` is rewritten to the latest `rust-v*`
  tag before every build so the CLI reports accurate versions.
- **Wrapper ergonomics** – `codex` shim adds auto-update toggles, metadata reports,
  and integrates cleanly with `PATH`-first helper directories.
- **Auditable by design** – logs land in `~/logs/codex-wrapper.log` and build metadata
  lives under `~/.local/share/codex-wrapper/` for forensics.

## 📦 Repository layout

```
README.md          # you are here
codex-updater      # build + install script (Bash)
codex              # wrapper shim that delegates to the real binary
docs/              # (reserved) future docs & diagrams
.github/           # CI + release workflows, issue templates
```

## 🚀 Quickstart

```bash
# Clone
git clone https://github.com/toxicwind/codex-updater.git
cd codex-updater

# Install locally (first-on-PATH helpers)
chmod +x codex codex-updater
mkdir -p ~/.local/bin-core
cp codex codex-updater ~/.local/bin-core/

# Run
codex --wrapper-version
```

Prefer piping from the release? Grab the tarball from the
[latest release](https://github.com/toxicwind/codex-updater/releases/latest)
and extract into your helper directory.

## 🧰 Wrapper flags

| Flag | Description |
| --- | --- |
| `--wrapper-update` | Run the updater before launching the CLI. |
| `--wrapper-rebuild` | Force a `cargo clean` + rebuild even if commit cached. |
| `--wrapper-no-update` | Skip auto-updates for this invocation. |
| `--wrapper-version` | Print cached commit/version metadata and exit. |
| `--wrapper-print-target` | Output the delegated binary path. |

Environment knobs:

| Variable | Purpose | Default |
| --- | --- | --- |
| `CODEX_WRAPPER_AUTO_UPDATE` | Enable background auto-update checks | `0` |
| `CODEX_WRAPPER_AUTO_INTERVAL` | Seconds between auto-updates | `86400` |
| `CODEX_UPDATER` | Override updater script path | `~/.local/bin-core/codex-updater` |
| `CODEX_BIN` | Override installed binary path | `~/.local/bin/codex` |

## 🧪 CI & Releases

- **CI (`ci.yml`)** runs `shfmt`, `shellcheck`, and optional Bats specs.
- **Release (`release.yml`)** archives `HEAD` on every push to `main` (or manual dispatch)
  and updates the `latest` tag with a fresh `codex-updater.tar.gz` artifact.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs, issues, and discussions are welcome.
Always run `make check` before opening a pull request.

## 🔐 Security

Report vulnerabilities privately via the GitHub security advisory flow or
security@hypebrut.sh. Public issues are fine for non-sensitive bugs.

## 📜 License

Released under the [Do What The Fuck You Want To Public License](LICENSE).
Enjoy, remix, and share improvements.
