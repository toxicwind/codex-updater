#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# purpose: push submodule first, then superproject, with GitHub sanity checks
# usage:   run from anywhere inside the superproject working tree
# notes:   requires git. uses gh if available to verify/create repos and defaults
###############################################################################

log() { printf "\033[1;36m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

need() { command -v "$1" >/dev/null 2>&1 || {
  err "missing required command: $1"
  exit 1
}; }

parse_remote() {
  # in: remote URL; out: owner repo
  # supports: git@github.com:owner/repo(.git)? | https://github.com/owner/repo(.git)?
  local url="$1" path owner repo
  case "$url" in
    git@github.com:*)
      path="${url#git@github.com:}"
      ;;
    https://github.com/*)
      path="${url#https://github.com/}"
      ;;
    ssh://git@github.com/*)
      path="${url#ssh://git@github.com/}"
      ;;
    *)
      echo "::" "::" # unknown
      return 0
      ;;
  esac
  path="${path%.git}"
  owner="${path%%/*}"
  repo="${path#*/}"
  printf "%s %s\n" "$owner" "$repo"
}

ensure_repo_exists() {
  # requires gh; args: owner repo visibility
  local owner="$1" repo="$2" vis="${3:-public}"
  if ! gh repo view "$owner/$repo" >/dev/null 2>&1; then
    warn "GitHub repo $owner/$repo not found; creating ($vis)"
    gh repo create "$owner/$repo" --"$vis" --confirm >/dev/null
    log "created https://github.com/$owner/$repo"
  fi
}

ensure_default_branch_main() {
  # requires gh; args: owner repo
  local owner="$1" repo="$2"
  local def
  def="$(gh repo view "$owner/$repo" --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo "")"
  if [ "$def" != "main" ] && [ -n "$def" ]; then
    warn "Default branch is $def; switching to main"
    # try to switch default; if protected, continue without failing
    gh api -X PATCH "repos/$owner/$repo" -f default_branch=main >/dev/null 2>&1 || true
  fi
}

push_current_branch() {
  # args: git_dir remote branch force_flag
  local dir="$1" remote="$2" branch="$3" force="${4:-}"
  git -C "$dir" push ${force:+-f} -u "$remote" "HEAD:$branch"
}

# 0) prereqs
need git
if command -v gh >/dev/null 2>&1; then
  if ! gh auth status >/dev/null 2>&1; then
    warn "gh is installed but not authenticated; continuing without gh API"
    USE_GH=0
  else
    USE_GH=1
  fi
else
  USE_GH=0
fi

# 1) resolve roots
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "${ROOT:-}" ]; then
  err "not inside a git repo"
  exit 1
fi
cd "$ROOT"

SUB_PATH="${SUB_PATH:-patches/community}"
SUPER_REMOTE="${SUPER_REMOTE:-origin}"
SUB_REMOTE="${SUB_REMOTE:-origin}"
SUB_BRANCH="${SUB_BRANCH:-main}"
SUPER_BRANCH="${SUPER_BRANCH:-main}"

log "superproject: $ROOT"
log "submodule:    $SUB_PATH"

# 2) ensure submodule is present and initialized
if [ ! -d "$SUB_PATH" ]; then
  err "expected submodule at $SUB_PATH. If missing, run: git submodule update --init --recursive"
  exit 1
fi
git submodule sync -- "$SUB_PATH" >/dev/null
git submodule update --init --recursive "$SUB_PATH" >/dev/null

# 3) discover remotes and GitHub coords
SUPER_URL="$(git -C "$ROOT" remote get-url "$SUPER_REMOTE" 2>/dev/null || true)"
SUB_URL="$(git -C "$SUB_PATH" remote get-url "$SUB_REMOTE" 2>/dev/null || true)"

read -r SUPER_OWNER SUPER_REPO <<<"$(parse_remote "$SUPER_URL")"
read -r SUB_OWNER SUB_REPO <<<"$(parse_remote "$SUB_URL")"

if [ -n "${SUPER_OWNER:-}" ] && [ "$USE_GH" -eq 1 ]; then
  ensure_repo_exists "$SUPER_OWNER" "$SUPER_REPO" public
  ensure_default_branch_main "$SUPER_OWNER" "$SUPER_REPO" || true
fi

if [ -n "${SUB_OWNER:-}" ] && [ "$USE_GH" -eq 1 ]; then
  ensure_repo_exists "$SUB_OWNER" "$SUB_REPO" public
  ensure_default_branch_main "$SUB_OWNER" "$SUB_REPO" || true
fi

# 4) normalize branches locally
# submodule
git -C "$SUB_PATH" fetch --all --tags --prune >/dev/null 2>&1 || true
if ! git -C "$SUB_PATH" show-ref --verify --quiet "refs/heads/$SUB_BRANCH"; then
  # if HEAD is detached, create branch at HEAD; else rename current to main
  CUR="$(git -C "$SUB_PATH" rev-parse --short HEAD)"
  log "creating submodule branch $SUB_BRANCH at $CUR"
  git -C "$SUB_PATH" branch "$SUB_BRANCH" >/dev/null 2>&1 || true
fi
git -C "$SUB_PATH" checkout "$SUB_BRANCH" >/dev/null 2>&1

# superproject
git -C "$ROOT" fetch "$SUPER_REMOTE" --prune >/dev/null 2>&1 || true
if ! git -C "$ROOT" show-ref --verify --quiet "refs/heads/$SUPER_BRANCH"; then
  log "creating superproject branch $SUPER_BRANCH"
  git -C "$ROOT" branch "$SUPER_BRANCH" >/dev/null 2>&1 || true
fi
git -C "$ROOT" checkout "$SUPER_BRANCH" >/dev/null 2>&1

# 5) commit and push submodule first
log "staging submodule changes (if any)"
git -C "$SUB_PATH" add -A
if ! git -C "$SUB_PATH" diff --cached --quiet; then
  git -C "$SUB_PATH" commit -m "sync: update community patches ($(date -u +%F))" >/dev/null
else
  log "no staged changes in submodule; skipping commit"
fi

# ensure upstream tracks main
if ! git -C "$SUB_PATH" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  warn "submodule has no upstream; will push and set -u to $SUB_REMOTE/$SUB_BRANCH"
fi
log "pushing submodule -> $SUB_REMOTE/$SUB_BRANCH"
push_current_branch "$SUB_PATH" "$SUB_REMOTE" "$SUB_BRANCH"

# 6) record new gitlink in superproject and push
log "recording new submodule gitlink in superproject"
git -C "$ROOT" add "$SUB_PATH" .gitmodules
if ! git -C "$ROOT" diff --cached --quiet; then
  git -C "$ROOT" commit -m "chore: bump $SUB_PATH to latest $SUB_BRANCH" >/dev/null
else
  log "no gitlink change to commit; superproject already up to date"
fi

# ensure upstream tracks main
if ! git -C "$ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  warn "superproject has no upstream; will push and set -u to $SUPER_REMOTE/$SUPER_BRANCH"
fi
log "pushing superproject -> $SUPER_REMOTE/$SUPER_BRANCH"
push_current_branch "$ROOT" "$SUPER_REMOTE" "$SUPER_BRANCH"

# 7) post-push validation (optional but helpful)
if [ "$USE_GH" -eq 1 ] && [ -n "${SUB_OWNER:-}" ]; then
  log "verifying submodule commit exists on GitHub"
  SUB_SHA="$(git -C "$SUB_PATH" rev-parse HEAD)"
  gh api "repos/$SUB_OWNER/$SUB_REPO/commits/$SUB_SHA" >/dev/null || warn "could not verify $SUB_SHA on GitHub (eventual consistency?)"
fi

log "done. submodule pushed first, superproject gitlink updated and pushed."
