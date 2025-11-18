# Determinate Nix auto-update configuration for theophany (macOS)
{ config, pkgs, lib, ... }:

{
  # Determinate Nix has built-in auto-update capabilities
  # Configure via launchd to check for updates weekly

  # Create update script
  environment.systemPackages = [
    (pkgs.writeScriptBin "determinate-nix-update" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      LOG_FILE="/var/log/determinate-nix-update.log"

      log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
      }

      log "Starting Determinate Nix update check"

      # Determinate Nix self-update
      if /nix/nix-installer self-upgrade 2>&1 | tee -a "$LOG_FILE"; then
        log "Determinate Nix update check completed"
      else
        log "Determinate Nix update check failed"
        exit 1
      fi

      log "Determinate Nix update completed"
    '')
  ];

  # Create launchd plist for auto-update
  launchd.daemons.determinate-nix-update = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "-c"
        "determinate-nix-update"
      ];
      StartCalendarInterval = [
        {
          Hour = 20;  # 01:00 UTC (8pm EST local time)
          Minute = 0;
          Weekday = 1;  # Monday
        }
        {
          Hour = 20;  # 01:00 UTC (8pm EST local time)
          Minute = 0;
          Weekday = 5;  # Friday
        }
      ];
      StandardErrorPath = "/var/log/determinate-nix-update.err.log";
      StandardOutPath = "/var/log/determinate-nix-update.out.log";
    };
  };
}
