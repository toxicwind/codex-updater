#!/usr/bin/env bash
# scripts/install-deps.sh
# Cross-distro bootstrap for build prerequisites + Rust (via rustup).
# Supports: Debian/Ubuntu, Fedora/RHEL/CentOS/Alma/Rocky, Arch/Manjaro, openSUSE, Alpine, NixOS.
# WSL: run inside your distro (Ubuntu, Debian, etc.) — same commands apply.

set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  SUDO=sudo
else
  SUDO=
fi

have() { command -v "$1" >/dev/null 2>&1; }

# shellcheck source=/dev/null
source /etc/os-release || {
  echo "Cannot detect distro (missing /etc/os-release)"
  exit 1
}
ID_LIKE_LOWER="$(echo "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"
ID_LOWER="$(echo "${ID:-}" | tr '[:upper:]' '[:lower:]')"

case "${ID_LOWER}" in
  ubuntu | debian | linuxmint | pop | neon | elementary)
    $SUDO apt-get update
    $SUDO apt-get install -y --no-install-recommends build-essential clang pkg-config libssl-dev git curl ca-certificates
    ;;
  fedora)
    # Group name must be quoted; works on Fedora 39+
    $SUDO dnf -y group install "development-tools"
    $SUDO dnf -y install gcc gcc-c++ clang make pkgconfig openssl-devel git curl ca-certificates
    ;;
  rhel | centos | rocky | almalinux)
    $SUDO dnf -y group install "Development Tools" || $SUDO yum -y groupinstall "Development Tools"
    $SUDO dnf -y install gcc gcc-c++ clang make pkgconfig openssl-devel git curl ca-certificates || $SUDO yum -y install gcc gcc-c++ clang make pkgconfig openssl-devel git curl ca-certificates
    ;;
  arch | artix | manjaro)
    $SUDO pacman -Sy --needed --noconfirm base-devel clang pkgconf openssl git curl ca-certificates
    ;;
  opensuse* | sles | suse)
    $SUDO zypper -n ref
    $SUDO zypper -n install -t pattern devel_basis || true
    $SUDO zypper -n install gcc gcc-c++ clang make pkgconf-pkg-config libopenssl-devel git curl ca-certificates
    ;;
  alpine)
    $SUDO apk add --no-cache build-base clang pkgconf openssl-dev git curl ca-certificates
    ;;
  nixos)
    echo "Detected NixOS. Use nix-shell or flakes to enter a dev shell with build tools and Rust:"
    echo "  nix-shell -p gcc pkg-config git curl cacert rustup"
    echo "  rustup-init"
    ;;
  *)
    # Try heuristics via ID_LIKE
    if [[ "${ID_LIKE_LOWER}" == *"debian"* ]]; then
      $SUDO apt-get update
      $SUDO apt-get install -y --no-install-recommends build-essential clang pkg-config libssl-dev git curl ca-certificates
    elif [[ "${ID_LIKE_LOWER}" == *"rhel"* ]] || [[ "${ID_LIKE_LOWER}" == *"fedora"* ]]; then
      $SUDO dnf -y group install "Development Tools" || $SUDO yum -y groupinstall "Development Tools"
      $SUDO dnf -y install gcc gcc-c++ clang make pkgconfig openssl-devel git curl ca-certificates || $SUDO yum -y install gcc gcc-c++ clang make pkgconfig openssl-devel git curl ca-certificates
    else
      echo "Unsupported or unrecognized distro (${ID_LOWER}). Install a C toolchain, pkg-config, curl, git, OpenSSL dev headers, and Rust manually."
      exit 1
    fi
    ;;
esac

# Install Rust via rustup if missing
if ! have rustup; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# Ensure stable toolchain
if have rustup; then
  rustup toolchain install stable
  rustup default stable
fi

echo "✓ Tooling ready. You can now run: codex --wrapper-update"
