{ config, lib, pkgs, ... }:

let
  binary = "/home/jason/.local/bin/bosun";
  configFile = "/home/jason/.config/bosun/bosun.toml";
  runtimeDir = "/run/user/1000";
  stateDir = "/home/jason/.local/state/bosun";
in {
  systemd.services.bosun-monitor = {
    description = "Sample bosun pane token burn";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "jason";
      Group = "users";
      WorkingDirectory = "/home/jason";
      Environment = [
        "XDG_RUNTIME_DIR=${runtimeDir}"
        "BOSUN_MONITOR_DIR=${stateDir}/monitor"
        "BOSUN_PANELEDGER_DIR=${stateDir}/cost-ledger"
      ];
      ExecStart = "${binary} monitor sample --config ${configFile}";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = false;
      ReadWritePaths = [ stateDir ];
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryMax = "256M";
    };
  };

  systemd.timers.bosun-monitor = {
    description = "Sample bosun pane token burn every 2 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "3min";
      OnUnitActiveSec = "2min";
      AccuracySec = "20s";
      Persistent = false;
    };
  };
}
