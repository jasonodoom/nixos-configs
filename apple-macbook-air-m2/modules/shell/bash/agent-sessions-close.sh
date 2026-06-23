#!/usr/bin/env bash
# Safely close the 'agents' tmux session: snapshot current state first so
# agent-sessions-restore can bring everything back, gracefully quit each
# agent CLI so its transcript flushes to disk, then tear down tmux.
#
# Usage:
#   agent-sessions-close          # snapshot, /exit each pane, wait, then kill
#   agent-sessions-close --force  # snapshot then kill now, no grace wait
#
# Override session name for testing: AGENT_SESSION=foo agent-sessions-close

set -u

SESSION="${AGENT_SESSION:-agents}"
GRACE_SECONDS="${AGENT_CLOSE_GRACE:-12}"
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --force|-f) FORCE=1 ;;
    -h|--help) echo "usage: agent-sessions-close [--force]"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

# 1. Snapshot first. Never tear down without a fresh snapshot, or the
# sessions become unrecoverable.
if command -v agent-sessions-snapshot >/dev/null 2>&1; then
  agent-sessions-snapshot >/dev/null 2>&1 || true
fi

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "No tmux session '$SESSION' to close. Snapshot refreshed."
  exit 0
fi

panes=$(tmux list-panes -s -t "$SESSION" -F '#{pane_id}' 2>/dev/null)
pane_count=$(printf '%s\n' "$panes" | grep -c . || true)

if [ "$FORCE" -eq 1 ]; then
  tmux kill-session -t "$SESSION"
  echo "Force-closed '$SESSION' ($pane_count panes). Snapshot saved; transcripts may be mid-write."
  echo "Restore with: agent-sessions-restore"
  exit 0
fi

# 2. Graceful quit per pane. A leading C-c clears any half-typed input or
# interrupts a running turn, then /exit asks the agent to quit cleanly so
# the transcript is flushed.
for p in $panes; do
  tmux send-keys -t "$p" C-c 2>/dev/null || true
done
sleep 1
for p in $panes; do
  tmux send-keys -t "$p" "/exit" Enter 2>/dev/null || true
done

# 3. Wait for panes to drain back to a bare shell, then kill the session.
deadline=$(( $(date +%s) + GRACE_SECONDS ))
while [ "$(date +%s)" -lt "$deadline" ]; do
  busy=0
  for p in $(tmux list-panes -s -t "$SESSION" -F '#{pane_id}' 2>/dev/null); do
    cmd=$(tmux display-message -p -t "$p" '#{pane_current_command}' 2>/dev/null)
    case "$cmd" in
      *claude*|*agy*|*node*) busy=1 ;;
    esac
  done
  [ "$busy" -eq 0 ] && break
  sleep 1
done

still_busy=0
for p in $(tmux list-panes -s -t "$SESSION" -F '#{pane_id}' 2>/dev/null); do
  cmd=$(tmux display-message -p -t "$p" '#{pane_current_command}' 2>/dev/null)
  case "$cmd" in
    *claude*|*agy*|*node*) still_busy=$((still_busy + 1)) ;;
  esac
done

tmux kill-session -t "$SESSION"
if [ "$still_busy" -gt 0 ]; then
  echo "Closed '$SESSION' ($pane_count panes); $still_busy did not quit within ${GRACE_SECONDS}s and were killed."
else
  echo "Closed '$SESSION' ($pane_count panes); all agents exited cleanly."
fi
echo "Restore with: agent-sessions-restore"
