{ config, pkgs, lib, ... }:

let
  snapshotScript = pkgs.writeShellScriptBin "agent-sessions-snapshot"
    (builtins.readFile ./agent-sessions-snapshot.sh);
  restoreScript = pkgs.writeShellScriptBin "agent-sessions-restore"
    (builtins.readFile ./agent-sessions-restore.sh);
  listScript = pkgs.writeShellScriptBin "agent-sessions-list"
    (builtins.readFile ./agent-sessions-list.sh);
  snapshotFile = "$HOME/.local/state/agent-sessions/snapshot";
in
{
  environment.systemPackages = [ snapshotScript restoreScript listScript ];

  programs.bash.interactiveShellInit = ''
    # Agent session restore hint: interactive non-tmux shells, snapshot
    # exists with at least one session, no live 'agents' tmux yet.
    if [[ $- == *i* ]] && [ -z "''${TMUX:-}" ] && command -v agent-sessions-restore >/dev/null 2>&1 && [ -f "${snapshotFile}" ]; then
      __as_live=$(awk -F= '/^LIVE_COUNT=/ {print $2; exit}' "${snapshotFile}" 2>/dev/null)
      __as_retained=$(awk -F= '/^RETAINED_COUNT=/ {print $2; exit}' "${snapshotFile}" 2>/dev/null)
      __as_total=$(( ''${__as_live:-0} + ''${__as_retained:-0} ))
      if [ "$__as_total" -gt 0 ] 2>/dev/null && ! tmux has-session -t agents 2>/dev/null; then
        if [ "''${__as_retained:-0}" -gt 0 ]; then
          printf '\n🤖 \033[1;33mAgent sessions: %d live, %d closed (within 24h)\033[0m. Run \033[1;36magent-sessions-restore\033[0m to restore all.\n' \
            "''${__as_live:-0}" "''${__as_retained:-0}"
        else
          printf '\n🤖 \033[1;33mAgent sessions: %d live\033[0m. Run \033[1;36magent-sessions-restore\033[0m to restore.\n' \
            "''${__as_live:-0}"
        fi
      fi
      unset __as_live __as_retained __as_total
    fi

    # Snapshot on shell exit. Backgrounded so logout isn't delayed.
    if [[ $- == *i* ]] && command -v agent-sessions-snapshot >/dev/null 2>&1; then
      __as_snap_on_exit() {
        ( agent-sessions-snapshot >/dev/null 2>&1 & ) 2>/dev/null
      }
      trap __as_snap_on_exit EXIT
    fi
  '';

  # Periodic snapshot via launchd. Safety net for hard crashes / sleeps
  # where the bash EXIT trap never fires. Every 5 minutes.
  launchd.user.agents.agent-sessions-snapshot = {
    serviceConfig = {
      Label = "com.jason.agent-sessions-snapshot";
      ProgramArguments = [ "${snapshotScript}/bin/agent-sessions-snapshot" ];
      StartInterval = 300;
      RunAtLoad = true;
      StandardOutPath = "/tmp/agent-sessions-snapshot.log";
      StandardErrorPath = "/tmp/agent-sessions-snapshot.err.log";
    };
  };
}
