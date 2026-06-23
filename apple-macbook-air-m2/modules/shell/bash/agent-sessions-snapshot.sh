#!/usr/bin/env bash
# Scan currently-running agent CLI processes (claude, agy) and merge them
# into a rolling snapshot. Sessions seen alive in the last TTL_SECONDS
# remain in the snapshot even after their process exits — closing a
# terminal does not drop the session from the restore list.
#
# Snapshot file format (sourceable bash):
#   SESSIONS=( "name|cwd|cmd|last_seen_epoch" ... )
# last_seen_epoch is unix seconds for portable comparison (no date parsing).
#
# Triggers: bash EXIT trap, launchd periodic (every 5 min), manual.

set -u

TTL_SECONDS=${AGENT_SESSIONS_TTL:-86400}   # 24 hours default
STATE_DIR="$HOME/.local/state/agent-sessions"
SNAPSHOT="$STATE_DIR/snapshot"
TMPFILE="$STATE_DIR/snapshot.tmp.$$"

mkdir -p "$STATE_DIR"

SELF_PID=$$
is_ancestor() {
  local pid=$1
  while [ "$pid" -gt 1 ]; do
    [ "$pid" = "$SELF_PID" ] && return 0
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    [ -z "$pid" ] && return 1
  done
  return 1
}

pid_cwd() {
  lsof -a -d cwd -p "$1" -Fn 2>/dev/null | awk '/^n/ {print substr($0,2); exit}'
}

slug() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g; s/^-*//; s/-*$//; s/--*/-/g' \
    | cut -c1-24
}

list_pids_named() {
  ps -axo pid,comm 2>/dev/null | awk -v n="$1" '$2==n {print $1}'
}

now_epoch=$(date -u +%s)
now_iso=$(date -u +%Y-%m-%dT%H:%M:%SZ)   # display only

# Key for each session: cwd + tab + cmd (unique enough; name is cosmetic).
# Stored value: name|cwd|cmd|last_seen_iso
declare -a entry_keys=()
declare -A entry_data=()

upsert_entry() {
  local name="$1" cwd="$2" cmd="$3" last_seen="$4"
  local key="$cwd"$'\t'"$cmd"
  if [ -z "${entry_data[$key]+x}" ]; then
    # First sight: register name + position.
    entry_keys+=("$key")
  else
    # Already seen: preserve user-set name (everything before first |).
    local existing="${entry_data[$key]}"
    name="${existing%%|*}"
  fi
  entry_data["$key"]="$name|$cwd|$cmd|$last_seen"
}

# 1. Load existing entries so sessions that have since closed persist
# until they age out via the TTL.
if [ -f "$SNAPSHOT" ]; then
  # shellcheck source=/dev/null
  . "$SNAPSHOT"
  if declare -p SESSIONS >/dev/null 2>&1; then
    for entry in "${SESSIONS[@]:-}"; do
      IFS='|' read -r e_name e_cwd e_cmd e_last <<<"$entry"
      [ -z "$e_cwd" ] && continue
      [ -z "$e_cmd" ] && continue
      # Last_seen is epoch seconds. Tolerate any garbage by defaulting to now.
      case "$e_last" in
        ''|*[!0-9]*) e_last="$now_epoch" ;;
      esac
      age=$(( now_epoch - e_last ))
      if [ "$age" -lt "$TTL_SECONDS" ] && [ "$age" -ge 0 ]; then
        upsert_entry "$e_name" "$e_cwd" "$e_cmd" "$e_last"
      fi
    done
  fi
  unset SESSIONS SNAPSHOT_AT
fi

# 2. Scan live claude --resume sessions, refresh last_seen.
seen_uuids=" "
for pid in $(list_pids_named claude); do
  is_ancestor "$pid" && continue
  cmd=$(ps -o command= -p "$pid" 2>/dev/null)
  case "$cmd" in *--resume*) ;; *) continue ;; esac
  case "$cmd" in *--fork-session*) continue ;; esac
  uuid=$(printf '%s' "$cmd" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
  [ -z "$uuid" ] && continue
  case "$seen_uuids" in *" $uuid "*) continue ;; esac
  seen_uuids+="$uuid "
  cwd=$(pid_cwd "$pid")
  [ -z "$cwd" ] && continue
  flags=""
  case "$cmd" in *--dangerously-skip-permissions*) flags="--dangerously-skip-permissions " ;; esac
  name=$(slug "$(basename "$cwd")")
  [ -z "$name" ] && name="session"
  upsert_entry "$name" "$cwd" "claude ${flags}--resume $uuid" "$now_epoch"
done

# 3. Scan bare claude (no --resume). Skip if a resumable entry already
# covers this cwd (live or from existing snapshot).
covered_cwds=" "
for key in "${entry_keys[@]}"; do
  c_cwd="${key%%$'\t'*}"
  c_cmd="${key#*$'\t'}"
  case "$c_cmd" in *--resume*) covered_cwds+="$c_cwd " ;; esac
done
for pid in $(list_pids_named claude); do
  is_ancestor "$pid" && continue
  cmd=$(ps -o command= -p "$pid" 2>/dev/null)
  case "$cmd" in *--resume*|*--fork-session*|*daemon*|*--bg-*) continue ;; esac
  cwd=$(pid_cwd "$pid")
  [ -z "$cwd" ] && continue
  case "$covered_cwds" in *" $cwd "*) continue ;; esac
  covered_cwds+="$cwd "
  flags=""
  case "$cmd" in *--dangerously-skip-permissions*) flags=" --dangerously-skip-permissions" ;; esac
  name=$(slug "$(basename "$cwd")")
  [ -z "$name" ] && name="session"
  upsert_entry "$name" "$cwd" "claude${flags}" "$now_epoch"
done

# 4. Scan agy --conversation.
for pid in $(list_pids_named agy); do
  is_ancestor "$pid" && continue
  cmd=$(ps -o command= -p "$pid" 2>/dev/null)
  case "$cmd" in *--conversation*) ;; *) continue ;; esac
  conv=$(printf '%s' "$cmd" | awk '{for(i=1;i<=NF;i++) if($i=="--conversation") print $(i+1)}' | head -1)
  [ -z "$conv" ] && continue
  cwd=$(pid_cwd "$pid")
  [ -z "$cwd" ] && continue
  name=$(slug "agy-$(basename "$cwd")")
  upsert_entry "$name" "$cwd" "agy --conversation $conv" "$now_epoch"
done

# 5. Write merged snapshot atomically. snapshot.prev is backup.
# Count how many entries were refreshed in THIS scan (live right now)
# vs how many are retained from prior snapshots (within TTL but not seen
# in this scan). Hint uses both to be unambiguous.
live_count=0
for key in "${entry_keys[@]}"; do
  ls_field="${entry_data[$key]##*|}"
  [ "$ls_field" = "$now_epoch" ] && live_count=$((live_count + 1))
done
retained_count=$(( ${#entry_keys[@]} - live_count ))

{
  printf '# Auto-generated by agent-sessions-snapshot.sh at %s\n' "$now_iso"
  printf '# Sessions captured: %d (%d live, %d retained-from-prior)\n' \
    "${#entry_keys[@]}" "$live_count" "$retained_count"
  printf '# TTL: %d seconds (entries older than this drop on next snapshot)\n' "$TTL_SECONDS"
  printf 'SNAPSHOT_AT=%q\n' "$now_iso"
  printf 'LIVE_COUNT=%d\n' "$live_count"
  printf 'RETAINED_COUNT=%d\n' "$retained_count"
  printf 'SESSIONS=(\n'
  for key in "${entry_keys[@]}"; do
    printf '  %q\n' "${entry_data[$key]}"
  done
  printf ')\n'
} > "$TMPFILE"

if [ -f "$SNAPSHOT" ]; then
  cp -f "$SNAPSHOT" "$SNAPSHOT.prev"
fi
mv -f "$TMPFILE" "$SNAPSHOT"

# Print a brief summary so users see what just got captured. Goes to
# stderr so callers redirecting stdout still get visible feedback;
# launchd's StandardErrorPath captures it for later inspection.
{
  printf 'agent-sessions: %d captured at %s\n' "${#entry_keys[@]}" "$now_iso"
  for key in "${entry_keys[@]}"; do
    value="${entry_data[$key]}"
    name="${value%%|*}"
    rest="${value#*|}"
    cmd_field="${rest#*|}"
    cmd_field="${cmd_field%|*}"
    uuid=$(printf '%s' "$cmd_field" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
    printf '  [%s] %s\n' "$name" "${uuid:-bare}"
  done
} >&2
