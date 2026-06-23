{ config, pkgs, lib, ... }:

let
  snapshotScript = pkgs.writeShellScriptBin "agent-sessions-snapshot"
    (builtins.readFile ./agent-sessions-snapshot.sh);
  restoreScript = pkgs.writeShellScriptBin "agent-sessions-restore"
    (builtins.readFile ./agent-sessions-restore.sh);
  snapshotFile = "$HOME/.local/state/agent-sessions/snapshot";
in
{
  environment.systemPackages = [ snapshotScript restoreScript ];

  programs.bash.interactiveShellInit = ''
    # Agent session restore hint: interactive non-tmux shells, snapshot
    # exists with at least one session, no live 'agents' tmux yet.
    if [[ $- == *i* ]] && [ -z "''${TMUX:-}" ] && command -v agent-sessions-restore >/dev/null 2>&1 && [ -f "${snapshotFile}" ]; then
      __as_count=$(awk '/^# Sessions captured:/ {print $NF; exit}' "${snapshotFile}" 2>/dev/null)
      if [ -n "$__as_count" ] && [ "$__as_count" -gt 0 ] 2>/dev/null \
         && ! tmux has-session -t agents 2>/dev/null; then
        printf '\n🤖 \033[1;33mAgent sessions (%d):\033[0m run \033[1;36magent-sessions-restore\033[0m to restore.\n' \
          "$__as_count"
      fi
      unset __as_count
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
