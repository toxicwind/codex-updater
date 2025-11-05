#!/usr/bin/env bash
# scripts/packager.sh
# Orchestrates formatting, linting, and helper tasks for Codex Updater.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHFMT_FLAGS=("-i" "2" "-ci")
SHELLCHECK_FLAGS=("-S" "style")

usage() {
  cat <<'USAGE'
Usage: packager <command>

Commands:
  fmt         Format shell sources in-place using shfmt (-w -i 2 -ci)
  fmt-check   Diff formatting without writing (shfmt -d -i 2 -ci)
  lint        Run shellcheck -S style on shell sources
  check       Run fmt then lint (writing formatting changes)
  help        Show this message
USAGE
}

collect_shell_sources() {
  local -a paths=()
  shopt -s nullglob
  paths=("$PROJECT_ROOT"/codex "$PROJECT_ROOT"/codex-updater "$PROJECT_ROOT"/run.sh "$PROJECT_ROOT"/scripts/*.sh)
  shopt -u nullglob
  local hook="$PROJECT_ROOT/.githooks/pre-commit"
  if [[ -f "$hook" ]]; then
    paths+=("$hook")
  fi
  if ((${#paths[@]} == 0)); then
    return 1
  fi
  printf '%s\n' "${paths[@]}"
}

ensure_tools() {
  local missing=()
  for tool in "$@"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing+=("$tool")
    fi
  done
  if ((${#missing[@]} > 0)); then
    printf 'Missing required tool(s): %s\n' "${missing[*]}" >&2
    exit 1
  fi
}

run_shfmt() {
  local mode="$1"
  ensure_tools shfmt
  mapfile -t sources < <(collect_shell_sources || true)
  if ((${#sources[@]} == 0)); then
    echo "No shell sources found." >&2
    return 0
  fi
  if [[ "$mode" == "write" ]]; then
    echo "Formatting shell files: ${sources[*]}"
    shfmt -w "${SHFMT_FLAGS[@]}" "${sources[@]}"
  else
    echo "Checking formatting (diff only): ${sources[*]}"
    shfmt -d "${SHFMT_FLAGS[@]}" "${sources[@]}"
  fi
}

run_shellcheck() {
  ensure_tools shellcheck
  mapfile -t sources < <(collect_shell_sources || true)
  if ((${#sources[@]} == 0)); then
    echo "No shell sources found." >&2
    return 0
  fi
  echo "Linting shell files: ${sources[*]}"
  shellcheck "${SHELLCHECK_FLAGS[@]}" "${sources[@]}"
}

cmd_fmt() {
  run_shfmt write
}

cmd_fmt_check() {
  run_shfmt diff
}

cmd_lint() {
  run_shellcheck
}

cmd_check() {
  cmd_fmt
  cmd_lint
}

main() {
  local cmd="${1:-help}"
  case "$cmd" in
    fmt)
      shift
      cmd_fmt "$@"
      ;;
    fmt-check)
      shift
      cmd_fmt_check "$@"
      ;;
    lint)
      shift
      cmd_lint "$@"
      ;;
    check)
      shift
      cmd_check "$@"
      ;;
    help | -h | --help) usage ;;
    *)
      printf 'Unknown command: %s\n\n' "$cmd" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
