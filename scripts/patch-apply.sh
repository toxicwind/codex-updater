#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$ROOT" ]] || {
  echo "Run from superproject."
  exit 1
}
CODEX="vendor/codex"
PATCHES_DIR="patches/community"
[[ -d "$CODEX" ]] || {
  echo "Missing $CODEX submodule"
  exit 1
}
[[ -d "$PATCHES_DIR" ]] || {
  echo "Missing $PATCHES_DIR submodule"
  exit 1
}

echo "[..] Resetting codex to clean state"
git -C "$CODEX" reset --hard
git -C "$CODEX" clean -fdx

echo "[..] Updating patch submodule"
git submodule update --remote "$PATCHES_DIR" || true

# Apply *.patch in deterministic order
count=0
while IFS= read -r -d '' p; do
  echo "[..] Applying $(basename "$p")"
  if ! git -C "$CODEX" am --3way --whitespace=fix "$p"; then
    echo "[-] Failed to apply $p. Aborting 'am' and exiting."
    git -C "$CODEX" am --abort || true
    exit 2
  fi
  count=$((count + 1))
done < <(find "$PATCHES_DIR" -maxdepth 1 -type f -name '*.patch' -print0 | sort -z)

echo "[OK] Applied $count patch(es)"
