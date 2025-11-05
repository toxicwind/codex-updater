<div align="center">

# Codex Updater ♻️

Make the OpenAI Codex CLI your own without playing tag with upstream releases.

<a href="LICENSE"><img src="https://img.shields.io/badge/license-WTFPL-magenta.svg" alt="License"></a>
<a href="https://github.com/toxicwind/codex-updater/actions/workflows/ci.yml"><img src="https://github.com/toxicwind/codex-updater/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
<a href="https://github.com/toxicwind/codex-updater/releases/latest"><img src="https://img.shields.io/github/v/release/toxicwind/codex-updater?label=latest" alt="Release"></a>

</div>

Codex Updater is a cross‑distro toolkit that builds Codex from source, with a small wrapper that adds auto‑update, logging, and commit‑aware caching so you only rebuild when upstream actually changes.

## Features

- Commit‑aware caching to avoid redundant rebuilds.  
- Tag‑aligned versions so `codex --version` matches the latest tag.  
- Cross‑distro bootstrap for apt, dnf/dnf5/yum, pacman, zypper, apk, and Linuxbrew.  
- Wrapper UX with on‑demand updates, metadata, and interval auto‑updates.  

## Requirements

- Linux or WSL with a supported package manager.  
- Rust toolchain (installed automatically via rustup if missing).  
- OpenSSL development headers (installed automatically where possible).  

## Install

```bash
chmod +x codex codex-updater
mkdir -p ~/.local/bin-core
cp codex codex-updater ~/.local/bin-core/

codex --wrapper-update
codex --wrapper-version
```

## Configuration

Wrapper env:  
- CODEX_UPDATER: override updater path (default: ~/.local/bin-core/codex-updater).  
- CODEX_BIN: override installed binary (default: ~/.local/bin/codex).  
- CODEX_WRAPPER_AUTO_UPDATE=1: enable background auto‑update.  
- CODEX_WRAPPER_AUTO_INTERVAL: seconds between auto‑update checks (default: 86400).  

Updater flags:  
- --prefix DIR, --branch NAME, --repo URL, --no-sudo, --force-rebuild, --cc/--cxx.  

## Cross‑distro notes

- Debian/Ubuntu: build-essential, pkg-config, libssl-dev.  
- Fedora/RHEL/CentOS/Alma/Rocky: Development Tools, pkgconf, openssl-devel.  
- Arch/Manjaro: base-devel, pkgconf, openssl.  
- openSUSE: pattern devel_basis, libopenssl-devel.  
- Alpine: build-base, pkgconfig, openssl-dev.  
- WSL: detected via kernel markers; certificates refreshed when available.  

## How it works

- Updater syncs, versions, builds release, caches by commit, and installs to prefix.  
- Wrapper runs updates on demand or at intervals, records metadata, and delegates.  

## Development

- make check runs shfmt and shellcheck.  
- Keep scripts portable and avoid distro‑specific assumptions.  

## Security & License

- See SECURITY.md for private reporting.  
- WTFPL v2 (LICENSE).  
