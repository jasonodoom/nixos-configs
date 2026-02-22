# Determinate Nix auto-update configuration for theophany (macOS)
{ config, pkgs, lib, ... }:

let
  updateScript = pkgs.writeScriptBin "determinate-nix-update" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    LOG_FILE="/var/log/determinate-nix-update.log"

    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
    }

    log "Starting Determinate Nix update check"

    # Determinate Nix update via determinate-nixd
    if determinate-nixd upgrade 2>&1 | tee -a "$LOG_FILE"; then
      log "Determinate Nix update completed"
    else
      log "Determinate Nix update failed"
      exit 1
    fi
  '';
in
{
  # Determinate Nix has built-in auto-update capabilities
  # Configure via launchd to check for updates weekly

  environment.systemPackages = [ updateScript ];

  # Create launchd plist for auto-update
  launchd.daemons.determinate-nix-update = {
    serviceConfig = {
      ProgramArguments = [
        "${updateScript}/bin/determinate-nix-update"
      ];
      StartCalendarInterval = [
        {
          Hour = 20;  # 8pm local time
          Minute = 0;
          Weekday = 1;  # Monday
        }
        {
          Hour = 20;  # 8pm local time
          Minute = 0;
          Weekday = 5;  # Friday
        }
      ];
      StandardErrorPath = "/var/log/determinate-nix-update.err.log";
      StandardOutPath = "/var/log/determinate-nix-update.out.log";
    };
  };
}
