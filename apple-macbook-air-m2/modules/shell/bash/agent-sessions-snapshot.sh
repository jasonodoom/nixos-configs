#!/usr/bin/env bash
# Scan currently-running agent CLI processes (claude, codex, agy) and merge
# them into a rolling snapshot. Sessions seen alive in the last TTL_SECONDS
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

# Resolve the same tmux socket the user's shell does. launchd runs this with
# none of the shell environment, and the /tmp default would point at a
# different server (or silently start one) rather than fail.
export TMUX_TMPDIR="${TMUX_TMPDIR:-$HOME/.local/run}"
[ -d "$TMUX_TMPDIR" ] || mkdir -p "$TMUX_TMPDIR"

# Rescue a server whose socket went missing underneath it. Deleting the
# socket does not kill tmux: the server keeps running with every session
# intact, but nothing can reach it, `tmux attach` reports "no server
# running", and the sessions are lost whenever it finally exits. tmux
# recreates its socket on SIGUSR1, so this is recoverable right up until
# that moment — which is the whole reason this ran too late once already.
#
# Only ever signal the server. SIGUSR1's default disposition is terminate,
# so hitting a client would kill it. The server is the daemonised one:
# reparented to init and holding no controlling terminal. A client always
# has the tty it was launched from.
#
# Narrow it further to servers bound to *our* socket directory. A server on
# some other socket (tmux -L, or one predating a TMUX_TMPDIR change) is not
# orphaned just because we cannot see it, and signalling it every five
# minutes would be noise. lsof still reports the bound path after the socket
# file is unlinked, which is precisely the case being detected.
tmux_server_pids() {
  local pid
  for pid in $(ps -axo pid,ppid,tty,comm 2>/dev/null \
                 | awk '$2 == 1 && $3 == "??" && $4 ~ /(^|\/)tmux$/ { print $1 }'); do
    if lsof -p "$pid" 2>/dev/null | grep -q "unix.*${TMUX_TMPDIR%/}/"; then
      printf '%s\n' "$pid"
    fi
  done
}

rescue_orphaned_server() {
  command -v tmux >/dev/null 2>&1 || return 0
  tmux ls >/dev/null 2>&1 && return 0   # reachable; nothing to rescue

  local pids
  pids=$(tmux_server_pids | tr '\n' ' ')
  [ -z "${pids// /}" ] && return 0      # no server at all; a cold start

  mkdir -p "$TMUX_TMPDIR"

  # One at a time, stopping as soon as the socket answers. There may be
  # unrelated servers on other sockets; signalling those is harmless (they
  # just rewrite a socket they already have) but pointless, and signalling
  # all of them makes it impossible to say which one was actually stuck.
  local pid
  for pid in $pids; do
    kill -USR1 "$pid" 2>/dev/null || continue
    sleep 1
    if tmux ls >/dev/null 2>&1; then
      printf 'agent-sessions: rescued orphaned tmux server (pid %s) — socket was missing from %s, recreated via SIGUSR1\n' \
        "$pid" "$TMUX_TMPDIR" >&2
      return 0
    fi
  done

  printf 'agent-sessions: tmux server(s) alive (pid %s) but still unreachable at %s after SIGUSR1 — they may have been started under a different TMUX_TMPDIR\n' \
    "${pids% }" "$TMUX_TMPDIR" >&2
}

rescue_orphaned_server

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

# First non-option argv word of an ssh command line is [user@]host. Options
# that take a separate value have to be stepped over or their value gets
# mistaken for the host (ssh -p 2222 host would otherwise yield "2222").
ssh_host_from_cmd() {
  local skip=0 first=1 tok
  # Word-splitting is wanted here, globbing is not: a remote command like
  # `ls *.log` would otherwise expand against the local cwd. `local -`
  # keeps the -f confined to this function.
  local -
  set -f
  for tok in $1; do
    # Skip argv0 by position. Matching it by name would also swallow a
    # host that happens to end in "ssh".
    if [ "$first" -eq 1 ]; then first=0; continue; fi
    if [ "$skip" -eq 1 ]; then skip=0; continue; fi
    case "$tok" in
      -[BbcDEeFIiJLlmOopQRSWw]) skip=1 ;;
      -*) ;;
      *) printf '%s' "${tok#*@}"; return 0 ;;
    esac
  done
  return 1
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

# 4. Scan codex resume sessions. Codex spells resume as a subcommand
# (`codex [--yolo] resume <uuid>`), so extract the uuid and rebuild a
# canonical resume command, preserving the dangerous-mode flag.
codex_covered=" "
seen_codex=" "
for pid in $(list_pids_named codex); do
  is_ancestor "$pid" && continue
  cmd=$(ps -o command= -p "$pid" 2>/dev/null)
  case "$cmd" in *" resume"*) ;; *) continue ;; esac
  uuid=$(printf '%s' "$cmd" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
  [ -z "$uuid" ] && continue
  case "$seen_codex" in *" $uuid "*) continue ;; esac
  seen_codex+="$uuid "
  cwd=$(pid_cwd "$pid")
  [ -z "$cwd" ] && continue
  codex_covered+="$cwd "
  flags=""
  case "$cmd" in *--yolo*) flags="--yolo " ;; esac
  name=$(slug "codex-$(basename "$cwd")")
  upsert_entry "$name" "$cwd" "codex ${flags}resume $uuid" "$now_epoch"
done

# 5. Scan bare codex (no resume subcommand). Skip cwds a codex resume
# entry already covers; a fresh `codex` in the right cwd is the best
# restore available when no session id is visible in argv.
for pid in $(list_pids_named codex); do
  is_ancestor "$pid" && continue
  cmd=$(ps -o command= -p "$pid" 2>/dev/null)
  case "$cmd" in *" resume"*|*" exec"*|*mcp*|*proto*) continue ;; esac
  cwd=$(pid_cwd "$pid")
  [ -z "$cwd" ] && continue
  case "$codex_covered" in *" $cwd "*) continue ;; esac
  codex_covered+="$cwd "
  flags=""
  case "$cmd" in *--yolo*) flags=" --yolo" ;; esac
  name=$(slug "codex-$(basename "$cwd")")
  upsert_entry "$name" "$cwd" "codex${flags}" "$now_epoch"
done

# 6. Scan agy --conversation.
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

# 7. Scan ssh sessions. An ssh window is as much a part of the working set
# as an agent one — losing it costs whatever remote tmux was on the other
# end — but there is no session id to resume, so the honest restore is to
# run the same command again. Skip the plumbing: multiplex control
# commands, forwarders, ProxyCommand hops, git transport and scripted
# probes are not windows anyone wants back.
ssh_covered=$'\n'
for pid in $(list_pids_named ssh); do
  is_ancestor "$pid" && continue
  cmd=$(ps -o command= -p "$pid" 2>/dev/null)
  case "$cmd" in
    *" -W "*|*" -O "*|*" -N "*|*" -D "*) continue ;;
    *git-upload-pack*|*git-receive-pack*) continue ;;
    *BatchMode=yes*) continue ;;
  esac
  case "$cmd" in *" "*) ;; *) continue ;; esac
  # '|' is the record separator, so a remote command containing one would
  # truncate the entry on read and restore something else entirely.
  case "$cmd" in *"|"*) continue ;; esac
  host=$(ssh_host_from_cmd "$cmd") || continue
  [ -z "$host" ] && continue
  # Dedupe on the command, not the host. Keying on host alone means a
  # throwaway `ssh perdurabo` can suppress the long-lived
  # `ssh -t perdurabo tmux a` window, which then ages out while alive.
  case "$ssh_covered" in *$'\n'"$cmd"$'\n'*) continue ;; esac
  ssh_covered+="$cmd"$'\n'
  cwd=$(pid_cwd "$pid")
  [ -z "$cwd" ] && cwd="$HOME"
  # Name after the host, not the cwd. A window called "perdurabo" says what
  # it is; one called "jason" (the local cwd basename) says nothing.
  name=$(slug "${host%%.*}")
  [ -z "$name" ] && continue
  upsert_entry "$name" "$cwd" "ssh ${cmd#* }" "$now_epoch"
done

# 8. Let live tmux window names win. Renaming a window is the obvious way
# to name a session, but the names above are guessed from the cwd
# basename, so without this a rename silently reverts on the next scan.
# Keyed on cwd + kind because one cwd can hold several windows (a claude
# and a codex in ~/code are different sessions).
entry_kind() {
  case "$1" in
    claude*) printf 'claude' ;;
    codex*)  printf 'codex' ;;
    ssh*)    printf 'ssh' ;;
    agy*)    printf 'agy' ;;
    *)       return 1 ;;
  esac
}

SESSION="${AGENT_SESSION:-agents}"
declare -A tmux_names=()
if command -v tmux >/dev/null 2>&1 && tmux has-session -t "$SESSION" 2>/dev/null; then
  while IFS=$'\t' read -r w_name w_path w_cmd; do
    [ -z "$w_path" ] && continue
    w_kind=$(entry_kind "$w_cmd") || continue
    tmux_names["$w_path"$'\t'"$w_kind"]="$w_name"
  done < <(tmux list-windows -t "$SESSION" \
             -F '#{window_name}'$'\t''#{pane_current_path}'$'\t''#{pane_current_command}' 2>/dev/null)
fi

for key in "${entry_keys[@]}"; do
  e_cwd="${key%%$'\t'*}"
  e_cmd="${key#*$'\t'}"
  e_kind=$(entry_kind "$e_cmd") || continue
  live_name="${tmux_names["$e_cwd"$'\t'"$e_kind"]:-}"
  [ -z "$live_name" ] && continue
  value="${entry_data[$key]}"
  entry_data["$key"]="$live_name|${value#*|}"
done

# 9. Drop anything on the ignore list. These are live sessions the scan
# legitimately found but that are not part of the agents session — an
# agent in its own terminal tab, say — so capturing them means restore
# opens a duplicate. Keyed on cwd + kind so a changed --resume id does
# not defeat it. Managed with agent-sessions-forget.
IGNORE_FILE="$STATE_DIR/ignored"
if [ -s "$IGNORE_FILE" ]; then
  kept_keys=()
  for key in "${entry_keys[@]}"; do
    i_cwd="${key%%$'\t'*}"
    i_cmd="${key#*$'\t'}"
    i_kind=$(entry_kind "$i_cmd") || i_kind=""
    if [ -n "$i_kind" ] && grep -qF "$i_cwd"$'\t'"$i_kind" "$IGNORE_FILE" 2>/dev/null; then
      unset 'entry_data[$key]'
      continue
    fi
    kept_keys+=("$key")
  done
  entry_keys=("${kept_keys[@]:-}")
  [ -z "${entry_keys[0]:-}" ] && entry_keys=()
fi

# 10. Write merged snapshot atomically. snapshot.prev is backup.
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
