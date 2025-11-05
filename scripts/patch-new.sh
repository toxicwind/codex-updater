#!/usr/bin/env bash
# Create a patch from staged changes inside vendor/codex into patches/local
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$ROOT" ]] || {
  echo "Run from superproject."
  exit 1
}
CODEX="vendor/codex"
OUT_DIR="patches/local"
mkdir -p "$OUT_DIR"
msg="${*:-unnamed change}"
cd "$CODEX"

# Require staged changes
if git diff --cached --quiet; then
  echo "[-] No staged changes in $CODEX. 'git add' first."
  exit 1
fi

# Generate numbered patch
ts="$(date +%Y%m%d%H%M%S)"
num="$(printf "%04d" "$((RANDOM % 9000 + 1000))")"
fname="${OUT_DIR}/${num}-${ts}-$(echo "$msg" | tr -cs 'A-Za-z0-9._-' '-' | sed 's/^-//; s/-$//').patch"
git format-patch --stdout --full-index --no-signature --no-stat --quiet --keep-subject -1 >"$ROOT/$fname"

echo "[OK] Wrote $fname"
echo "Tip: move to patches/community after review and 'git add' it as a tracked patch."
