{ config, pkgs, lib, ... }:

let
  snapshotBin = "$HOME/bin/agent-sessions-snapshot.sh";
  restoreBin = "$HOME/bin/agent-sessions-restore.sh";
  snapshotFile = "$HOME/.local/state/agent-sessions/snapshot";
  daemonLabel = "com.jason.agent-sessions-snapshot";
in
{
  programs.bash.interactiveShellInit = ''
    # Agent session restore hint: only on interactive non-tmux shells when
    # we have a snapshot with at least one session and no live 'agents'
    # tmux session yet. Reads snapshot's own SESSIONS count for accuracy.
    if [[ $- == *i* ]] && [ -z "''${TMUX:-}" ] && [ -x "${restoreBin}" ] && [ -f "${snapshotFile}" ]; then
      __as_count=$(awk -F= '/^# Sessions captured:/ {print $1; exit}' "${snapshotFile}" 2>/dev/null | awk '{print $NF}')
      if [ -n "$__as_count" ] && [ "$__as_count" -gt 0 ] 2>/dev/null \
         && ! tmux has-session -t agents 2>/dev/null; then
        printf '\n🤖 \033[1;33mAgent sessions (%d):\033[0m run \033[1;36mbash %s\033[0m to restore.\n' \
          "$__as_count" "${restoreBin}"
      fi
      unset __as_count
    fi

    # Snapshot agent sessions on shell exit. Captures pre-reboot state and
    # any post-snapshot edits the user made (closed sessions, new ones).
    # Backgrounded + disowned so a slow scan never delays logout.
    if [[ $- == *i* ]] && [ -x "${snapshotBin}" ]; then
      __as_snap_on_exit() {
        ( "${snapshotBin}" >/dev/null 2>&1 & ) 2>/dev/null
      }
      trap __as_snap_on_exit EXIT
    fi
  '';

  # Periodic snapshot via launchd — safety net for hard crashes / sleeps
  # where the bash EXIT trap never fires. Every 5 minutes (300s).
  launchd.user.agents.agent-sessions-snapshot = {
    serviceConfig = {
      Label = daemonLabel;
      ProgramArguments = [ "/bin/bash" "-lc" "${snapshotBin}" ];
      StartInterval = 300;
      RunAtLoad = true;
      StandardOutPath = "/tmp/agent-sessions-snapshot.log";
      StandardErrorPath = "/tmp/agent-sessions-snapshot.err.log";
    };
  };
}
