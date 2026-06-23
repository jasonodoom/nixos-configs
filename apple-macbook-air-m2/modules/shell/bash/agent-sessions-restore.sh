#!/usr/bin/env bash
# Restore agent sessions (claude, codex, agy) into a named tmux session
# so they survive reboots and terminal close. Reads its session list from
# the most recent snapshot written by agent-sessions-snapshot.sh.
#
# Usage:
#   bash ~/bin/agent-sessions-restore.sh
#   tmux attach -t agents
#
# Override snapshot file: AGENT_SNAPSHOT=/path/to/snap bash ~/bin/agent-sessions-restore.sh
# Pin sessions manually: edit ~/.local/state/agent-sessions/snapshot directly
# (will be overwritten on next auto-snapshot unless you disable the trigger).

set -euo pipefail

SESSION=agents
STATE_DIR="$HOME/.local/state/agent-sessions"
SNAPSHOT="${AGENT_SNAPSHOT:-$STATE_DIR/snapshot}"

if [ ! -f "$SNAPSHOT" ]; then
  echo "No snapshot at $SNAPSHOT. Run agent-sessions-snapshot.sh while agent sessions are live."
  exit 1
fi

# Source the snapshot (defines SESSIONS=(...) and SNAPSHOT_AT)
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
  IFS='|' read -r name cwd cmd <<<"$entry"
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
