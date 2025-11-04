<div align="center">

# Codex Updater ♻️

**Commit-aware build + wrapper for the OpenAI Codex CLI.**

[![License: WTFPL](https://img.shields.io/badge/license-WTFPL-magenta.svg)](LICENSE)
[![CI](https://github.com/toxicwind/codex-updater/actions/workflows/ci.yml/badge.svg)](https://github.com/toxicwind/codex-updater/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/toxicwind/codex-updater?label=latest)](https://github.com/toxicwind/codex-updater/releases/latest)

</div>

## Why

The stock `codex` installer rebuilds from scratch every run and forgets which commit you already built. This project adds:

- **Commit-aware caching** — skip rebuilds when upstream hasn’t moved.
- **Tag-stamped binaries** — auto-sync `Cargo.toml` version with the latest `rust-v*` tag.
- **Wrapper tooling** — `codex` shim adds auto-update flags, metadata output, and logging hooks.

## What’s inside

```
codex-updater   # build + install script (bash)
codex           # wrapper shim, sits first on PATH
```

Both scripts are portable Bash (5.0+). Drop them in `~/.local/bin-core` or wherever you keep first-on-PATH helpers.

## Install

```bash
curl -fsSLO https://raw.githubusercontent.com/toxicwind/codex-updater/main/codex-updater
curl -fsSLO https://raw.githubusercontent.com/toxicwind/codex-updater/main/codex
chmod +x codex codex-updater
mv codex codex-updater ~/.local/bin-core/
```

Optional: grab the tarball from the [latest release](https://github.com/toxicwind/codex-updater/releases/latest).

## Usage

Run the wrapper exactly like the original CLI:

```bash
codex --help
```

Wrapper-only flags:

| Flag | Description |
| --- | --- |
| `--wrapper-update` | Force an update before running `codex`. |
| `--wrapper-rebuild` | Force rebuild (cargo clean) + update. |
| `--wrapper-no-update` | Skip auto-updates even if enabled via env. |
| `--wrapper-version` | Print cached build metadata & exit. |
| `--wrapper-print-target` | Show the delegated binary path. |

Environment knobs:

- `CODEX_WRAPPER_AUTO_UPDATE=1` — turn on background updates (default interval 24h).
- `CODEX_WRAPPER_AUTO_INTERVAL=3600` — change the auto-update interval (seconds).
- `CODEX_UPDATER` / `CODEX_BIN` — override paths for custom layouts.

Logs land in `~/logs/codex-wrapper.log`, metadata in `~/.local/share/codex-wrapper/`.

## Release automation

- **CI**: shfmt + shellcheck + bats
- **Release**: `latest` tag updated on every push to main with a fresh tarball artifact.

## License

[WTFPL](LICENSE) — do what the ♥️ you want.

