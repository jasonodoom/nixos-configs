#!/usr/bin/env bash
# Restore agent sessions into a named tmux session so they survive
# reboots and terminal close. Reads the snapshot maintained by
# agent-sessions-snapshot.sh — includes both live sessions and ones
# seen within the snapshot's TTL window.
#
# Usage:
#   agent-sessions-restore
#   tmux attach -t agents
#
# Override snapshot file: AGENT_SNAPSHOT=/path/to/snap agent-sessions-restore

set -euo pipefail

SESSION=agents
STATE_DIR="$HOME/.local/state/agent-sessions"
SNAPSHOT="${AGENT_SNAPSHOT:-$STATE_DIR/snapshot}"

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
  echo "tmux session '$SESSION' already exists. Attach with: tmux attach -t $SESSION"
  exit 0
fi

first=1
for entry in "${SESSIONS[@]}"; do
  # Entry: name|cwd|cmd|last_seen. last_seen is optional (older format).
  IFS='|' read -r name cwd cmd _last <<<"$entry"
  full="cd $(printf '%q' "$cwd") && $cmd"
  if (( first )); then
    tmux new-session -d -s "$SESSION" -n "$name" -c "$cwd" "bash -lc $(printf '%q' "$full")"
    first=0
  else
    tmux new-window -t "$SESSION" -n "$name" -c "$cwd" "bash -lc $(printf '%q' "$full")"
  fi
done

echo "Restored tmux session '$SESSION' with ${#SESSIONS[@]} windows from snapshot ($SNAPSHOT_AT)."
echo "Attach with: tmux attach -t $SESSION"
