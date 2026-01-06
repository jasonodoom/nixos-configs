# Darwin auto-update from GitHub repository
{ config, pkgs, lib, ... }:

{
  # Create update script
  environment.systemPackages = [
    (pkgs.writeScriptBin "darwin-auto-update" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      LOG_FILE="/var/log/darwin-auto-update.log"
      REPO_URL="https://github.com/jasonodoom/nixos-configs.git"
      REPO_DIR="/var/lib/darwin-config"
      BRANCH="main"

      log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
      }

      # Check if on AC power
      if ! /usr/bin/pmset -g ps | grep -q "AC Power"; then
        log "Not on AC power, skipping update"
        exit 0
      fi

      log "Starting darwin auto-update"

      # Clone or update repo
      if [ -d "$REPO_DIR/.git" ]; then
        log "Updating existing repo"
        cd "$REPO_DIR"
        ${pkgs.git}/bin/git fetch origin "$BRANCH"
        ${pkgs.git}/bin/git reset --hard "origin/$BRANCH"
      else
        log "Cloning repo"
        rm -rf "$REPO_DIR"
        ${pkgs.git}/bin/git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
        cd "$REPO_DIR"
      fi

      log "Current commit: $(${pkgs.git}/bin/git rev-parse --short HEAD)"

      # Run darwin-rebuild
      log "Running darwin-rebuild switch"
      cd "$REPO_DIR/apple-macbook-air-m2"
      if /run/current-system/sw/bin/darwin-rebuild switch --flake .#theophany 2>&1 | tee -a "$LOG_FILE"; then
        log "darwin-rebuild completed successfully"
      else
        log "darwin-rebuild failed"
        exit 1
      fi

      log "Darwin auto-update completed"
    '')
  ];

  # Create launchd daemon for auto-update
  launchd.daemons.darwin-auto-update = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "-c"
        "/run/current-system/sw/bin/darwin-auto-update"
      ];
      StartCalendarInterval = [
        {
          Hour = 21;  # 9pm local time
          Minute = 0;
        }
      ];
      StandardErrorPath = "/var/log/darwin-auto-update.err.log";
      StandardOutPath = "/var/log/darwin-auto-update.out.log";
    };
  };
}
