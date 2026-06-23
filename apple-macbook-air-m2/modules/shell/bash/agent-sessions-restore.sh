#!/usr/bin/env bash
# Restore agent sessions into a named tmux session so they survive
# reboots and terminal close. Reads the snapshot maintained by
# agent-sessions-snapshot.sh — includes both live sessions and ones
# seen within the snapshot's TTL window.
#
# Usage:
#   agent-sessions-restore           # rebuild and attach
#   agent-sessions-restore --no-attach
#
# Override snapshot file: AGENT_SNAPSHOT=/path/to/snap agent-sessions-restore

set -euo pipefail

SESSION=agents
STATE_DIR="$HOME/.local/state/agent-sessions"
SNAPSHOT="${AGENT_SNAPSHOT:-$STATE_DIR/snapshot}"
ATTACH=1

for arg in "$@"; do
  case "$arg" in
    --no-attach) ATTACH=0 ;;
    -h|--help) echo "usage: agent-sessions-restore [--no-attach]"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

# Attach to the session if we have a terminal. From inside tmux, switch the
# client instead of nesting; otherwise just print how to attach.
attach_session() {
  if [ "$ATTACH" -eq 0 ] || [ ! -t 1 ]; then
    echo "Attach with: tmux attach -t $SESSION"
  elif [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$SESSION" 2>/dev/null \
      || echo "Already in tmux. Switch with: tmux switch-client -t $SESSION"
  else
    exec tmux attach -t "$SESSION"
  fi
}

if [ ! -f "$SNAPSHOT" ]; then
  echo "No snapshot at $SNAPSHOT. Run agent-sessions-snapshot while sessions are live."
  exit 1
fi

# shellcheck source=/dev/null
. "$SNAPSHOT"

if [ "${#SESSIONS[@]}" -eq 0 ]; then
  echo "Snapshot has no sessions to restore (taken $SNAPSHOT_AT)."
  exit 0
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "tmux session '$SESSION' already exists."
  attach_session
  exit 0
fi

first=1
for entry in "${SESSIONS[@]}"; do
  # Entry: name|cwd|cmd|last_seen. last_seen is optional (older format).
  IFS='|' read -r name cwd cmd _last <<<"$entry"
  full="cd $(printf '%q' "$cwd") && $cmd"
  if (( first )); then
    tmux new-session -d -s "$SESSION" -n "$name" -c "$cwd" "bash -lic $(printf '%q' "$full")"
    first=0
  else
    tmux new-window -t "$SESSION" -n "$name" -c "$cwd" "bash -lic $(printf '%q' "$full")"
  fi
done

echo "Restored tmux session '$SESSION' with ${#SESSIONS[@]} windows from snapshot ($SNAPSHOT_AT)."
attach_session
