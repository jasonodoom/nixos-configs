{ config, lib, pkgs, ... }:

let
  binary = "/home/jason/.local/bin/bosun";
  configFile = "/home/jason/.config/bosun/bosun.toml";
  runtimeDir = "/run/user/1000";

  # Set to false only after a dry-run day looks right in the journal.
  dryRun = true;
  dryRunFlag = lib.optionalString dryRun " --dry-run";
in {
  systemd.services.bosun-limit-resume = {
    description = "Type Resume into panes whose usage limit has expired";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "jason";
      Group = "users";
      WorkingDirectory = "/home/jason";
      Environment = [ "XDG_RUNTIME_DIR=${runtimeDir}" ];
      ExecStart = "${binary} limit-resume watch --config ${configFile} --interval 60s${dryRunFlag}";
      Restart = "on-failure";
      RestartSec = "30s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = false;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryMax = "128M";
    };
  };
}
