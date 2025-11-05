#!/usr/bin/env bash
# Promote a local patch to the community submodule and push it
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$ROOT" ]] || {
  echo "Run from superproject."
  exit 1
}
SRC="${1:-}"
[[ -n "$SRC" ]] || {
  echo "Usage: $0 patches/local/XXXX-*.patch"
  exit 1
}
[[ -f "$SRC" ]] || {
  echo "[-] Not a file: $SRC"
  exit 1
}

COMM="patches/community"
[[ -d "$COMM/.git" ]] || {
  echo "[-] Missing submodule $COMM"
  exit 1
}

dest="$COMM/$(basename "$SRC")"
cp "$SRC" "$dest"
(cd "$COMM" && git add "$(basename "$dest")" && git commit -m "patch: add $(basename "$dest")")
# Push if possible
if git -C "$COMM" remote get-url origin >/dev/null 2>&1; then
  git -C "$COMM" push -u origin HEAD:main || true
fi
echo "[OK] Promoted $(basename "$SRC") to $COMM"
