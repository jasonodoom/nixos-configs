#!/usr/bin/env bash
# Print the current agent-sessions snapshot in a human-readable form.
# Lets you check what would be restored without rummaging in the state file.

set -u

STATE_DIR="$HOME/.local/state/agent-sessions"
SNAPSHOT="${AGENT_SNAPSHOT:-$STATE_DIR/snapshot}"

if [ ! -f "$SNAPSHOT" ]; then
  echo "No snapshot at $SNAPSHOT."
  exit 1
fi

# shellcheck source=/dev/null
. "$SNAPSHOT"

now=$(date -u +%s)
count=${#SESSIONS[@]}

if [ "$count" -eq 0 ]; then
  echo "Snapshot empty (taken $SNAPSHOT_AT)."
  exit 0
fi

printf 'Snapshot taken at: %s\n' "$SNAPSHOT_AT"
printf 'Sessions captured: %d\n\n' "$count"

idx=0
for entry in "${SESSIONS[@]}"; do
  IFS='|' read -r name cwd cmd last_seen <<<"$entry"
  uuid=$(printf '%s' "$cmd" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
  perms="default"
  case "$cmd" in *--dangerously-skip-permissions*) perms="--dangerously-skip-permissions" ;; esac
  age=""
  case "$last_seen" in
    ''|*[!0-9]*) age="?" ;;
    *)
      diff=$(( now - last_seen ))
      if [ "$diff" -lt 60 ]; then age="${diff}s ago"
      elif [ "$diff" -lt 3600 ]; then age="$(( diff / 60 ))m ago"
      elif [ "$diff" -lt 86400 ]; then age="$(( diff / 3600 ))h ago"
      else age="$(( diff / 86400 ))d ago"
      fi
      ;;
  esac
  printf '  %d. [%s]\n' "$idx" "$name"
  printf '       cwd:   %s\n' "$cwd"
  printf '       uuid:  %s\n' "${uuid:-(bare claude, no resume target)}"
  printf '       perms: %s\n' "$perms"
  printf '       seen:  %s\n\n' "$age"
  idx=$((idx+1))
done
