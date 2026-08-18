#!/usr/bin/env bash
# Keep a session out of the snapshot, and so out of restores.
#
# The scanner finds every live claude/codex/agy/ssh process, whether or
# not it belongs to the 'agents' tmux session, so an agent running in its
# own terminal tab is captured too and comes back as a duplicate window on
# the next restore. Dropping it from the snapshot file is not enough: the
# process is still alive, so the next scan five minutes later puts it
# straight back. This keeps a persistent ignore list the scanner consults.
#
# Usage:
#   agent-sessions-forget <name>...     stop capturing these sessions
#   agent-sessions-forget --list        show what is ignored
#   agent-sessions-forget --clear <name>|--all
#
# Entries are keyed on cwd + agent kind, not the exact command, so a
# claude session that changes its --resume id stays ignored.

set -u

STATE_DIR="$HOME/.local/state/agent-sessions"
SNAPSHOT="${AGENT_SNAPSHOT:-$STATE_DIR/snapshot}"
IGNORE="$STATE_DIR/ignored"

mkdir -p "$STATE_DIR"
[ -f "$IGNORE" ] || : > "$IGNORE"

entry_kind() {
  case "$1" in
    claude*) printf 'claude' ;;
    codex*)  printf 'codex' ;;
    ssh*)    printf 'ssh' ;;
    agy*)    printf 'agy' ;;
    *)       return 1 ;;
  esac
}

usage() {
  echo "usage: agent-sessions-forget <name>... | --list | --clear <name>|--all" >&2
  exit 2
}

[ "$#" -eq 0 ] && usage

if [ "$1" = "--list" ]; then
  if [ ! -s "$IGNORE" ]; then
    echo "Nothing ignored."
    exit 0
  fi
  echo "Ignored (not captured, not restored):"
  while IFS=$'\t' read -r i_cwd i_kind i_name; do
    [ -z "$i_cwd" ] && continue
    printf '  %-20s %-7s %s\n' "${i_name:-?}" "$i_kind" "$i_cwd"
  done < "$IGNORE"
  exit 0
fi

if [ "$1" = "--clear" ]; then
  shift
  [ "$#" -eq 0 ] && usage
  if [ "$1" = "--all" ]; then
    : > "$IGNORE"
    echo "Ignore list cleared; all sessions will be captured again."
  else
    for name in "$@"; do
      tmp=$(mktemp)
      awk -F'\t' -v n="$name" '$3 != n' "$IGNORE" > "$tmp" && mv -f "$tmp" "$IGNORE"
      echo "No longer ignoring: $name"
    done
  fi
  # Rescan so the session reappears in the snapshot immediately. Without
  # this it stays absent until the next scheduled scan, and a name that
  # is not in the snapshot cannot be resolved back into an ignore entry.
  if command -v agent-sessions-snapshot >/dev/null 2>&1; then
    agent-sessions-snapshot >/dev/null 2>&1 || true
  fi
  exit 0
fi

if [ ! -f "$SNAPSHOT" ]; then
  echo "No snapshot at $SNAPSHOT." >&2
  exit 1
fi

# shellcheck source=/dev/null
. "$SNAPSHOT"

for name in "$@"; do
  case "$name" in -*) usage ;; esac
  found=0
  for entry in "${SESSIONS[@]:-}"; do
    IFS='|' read -r e_name e_cwd e_cmd _rest <<<"$entry"
    [ "$e_name" = "$name" ] || continue
    kind=$(entry_kind "$e_cmd") || continue
    if grep -qF "$e_cwd"$'\t'"$kind" "$IGNORE" 2>/dev/null; then
      echo "Already ignored: $name ($kind in $e_cwd)"
    else
      printf '%s\t%s\t%s\n' "$e_cwd" "$kind" "$name" >> "$IGNORE"
      echo "Ignoring: $name ($kind in $e_cwd)"
    fi
    found=1
    break
  done
  if [ "$found" -eq 0 ]; then
    echo "Not in the snapshot: $name (run agent-sessions-snapshot, or check agent-sessions-list for the exact name)" >&2
    exit 1
  fi
done

# Drop them from the current snapshot too, so the change shows up before
# the next scheduled scan rather than five minutes later.
if command -v agent-sessions-snapshot >/dev/null 2>&1; then
  agent-sessions-snapshot >/dev/null 2>&1 || true
fi

echo "Run agent-sessions-list to confirm."
