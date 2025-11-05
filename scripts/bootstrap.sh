#!/usr/bin/env bash
# scripts/bootstrap.sh
# Convenience wrapper: install deps, then place wrapper/updater into ~/.local/bin-core and run first update.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

"${SCRIPT_DIR}/install-deps.sh"
mkdir -p "$HOME/.local/bin-core"
install -m 0755 "${REPO_DIR}/codex" "$HOME/.local/bin-core/codex"
install -m 0755 "${REPO_DIR}/codex-updater" "$HOME/.local/bin-core/codex-updater"

# Ensure the just-installed wrapper is first on PATH for this run
export PATH="$HOME/.local/bin-core:$PATH"

echo
echo "Running initial build via: codex --wrapper-update"
codex --wrapper-update || {
  echo "codex --wrapper-update failed; check the logs above and ensure build deps/Rust are installed." >&2
  exit 1
}

echo
echo "Add to your shell rc if not present:"
# shellcheck disable=SC2016
echo '  export PATH="$HOME/.local/bin-core:$PATH"'
echo
echo "Enable repo hooks (once per clone):"
echo '  git config core.hooksPath .githooks'
echo
echo "Bootstrap complete. You can now run: codex <args>"
