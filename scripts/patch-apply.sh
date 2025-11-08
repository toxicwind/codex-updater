#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$ROOT" ]] || {
  echo "Run from superproject."
  exit 1
}
CODEX="$ROOT/vendor/codex"
COMMUNITY_PATCHES_REL="patches/community"
LOCAL_PATCHES_REL="patches/local"
COMMUNITY_PATCHES="$ROOT/$COMMUNITY_PATCHES_REL"
LOCAL_PATCHES="$ROOT/$LOCAL_PATCHES_REL"
[[ -d "$CODEX" ]] || {
  echo "Missing $CODEX submodule"
  exit 1
}
[[ -d "$COMMUNITY_PATCHES" ]] || {
  echo "Missing $COMMUNITY_PATCHES submodule"
  exit 1
}

echo "[..] Resetting codex to clean state"
git -C "$CODEX" reset --hard
git -C "$CODEX" clean -fdx

PATCHES_UPDATE_COMMUNITY="${PATCHES_UPDATE_COMMUNITY:-1}"
if [[ "${PATCHES_UPDATE_COMMUNITY,,}" =~ ^(1|true|yes|on)$ ]]; then
  echo "[..] Updating patch submodule"
  git -C "$ROOT" submodule update --remote "$COMMUNITY_PATCHES_REL" || true
else
  echo "[..] Skipping community patch submodule update (PATCHES_UPDATE_COMMUNITY=$PATCHES_UPDATE_COMMUNITY)"
fi

load_patch_env() {
  local env_file=$1
  if [[ -r "$env_file" ]]; then
    # shellcheck disable=SC1090
    {
      set -a
      source "$env_file"
      set +a
    }
  fi
}

should_apply_patch() {
  local patch_basename=$1
  local key="PATCH_${patch_basename^^}"
  key=${key//[^A-Z0-9]/_}
  local raw_value=${!key:-1}
  case "${raw_value,,}" in
    0 | false | off | no) return 1 ;;
    *) return 0 ;;
  esac
}

apply_patch_dir() {
  local patch_dir=$1
  local label=$2
  local env_file="$patch_dir/.env"
  [[ -d "$patch_dir" ]] || return 0
  load_patch_env "$env_file"

  while IFS= read -r -d '' patch_file; do
    local base
    base=$(basename "$patch_file")
    local env_key="PATCH_${base^^}"
    env_key=${env_key//[^A-Z0-9]/_}
    if ! should_apply_patch "$base"; then
      echo "[..] Skipping $base (disabled via ${env_key})"
      continue
    fi
    echo "[..] Applying $label patch ${base}"
    local patch_abs
    patch_abs="$(cd "$(dirname "$patch_file")" && pwd)/$base"
    if ! git -C "$CODEX" am --3way --whitespace=fix "$patch_abs"; then
      echo "[-] Failed to apply $patch_file. Aborting 'am' and exiting."
      git -C "$CODEX" am --abort || true
      exit 2
    fi
  done < <(find "$patch_dir" -maxdepth 1 -type f -name '*.patch' -print0 | sort -z)
}

apply_patch_dir "$COMMUNITY_PATCHES" "community"
apply_patch_dir "$LOCAL_PATCHES" "local"

echo "[OK] Applied patches (respecting env toggles)"
