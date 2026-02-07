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

      create_failure_issue() {
        local log_content="$1"
        local commit="$2"

        log "Creating GitHub issue for update failure"

        su - jason -c "
          ${pkgs.gh}/bin/gh issue create \
            --repo jasonodoom/nixos-configs \
            --title 'darwin-auto-update failed on theophany ($(date +%Y-%m-%d))' \
            --body \"The scheduled darwin-auto-update failed on theophany.

**Commit:** $commit
**Time:** $(date)

<details>
<summary>Build log (last 100 lines)</summary>

\\\`\\\`\\\`
$log_content
\\\`\\\`\\\`

</details>\" \
            --assignee jasonodoom
        "
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

      CURRENT_COMMIT=$(${pkgs.git}/bin/git rev-parse --short HEAD)
      log "Current commit: $CURRENT_COMMIT"

      # Run darwin-rebuild and capture output
      log "Running darwin-rebuild switch"
      cd "$REPO_DIR/apple-macbook-air-m2"

      BUILD_OUTPUT=$(mktemp)
      if /run/current-system/sw/bin/darwin-rebuild switch --flake .#theophany 2>&1 | tee -a "$LOG_FILE" | tee "$BUILD_OUTPUT"; then
        log "darwin-rebuild completed successfully"
        rm -f "$BUILD_OUTPUT"
      else
        log "darwin-rebuild failed"
        LOG_TAIL=$(tail -100 "$BUILD_OUTPUT")
        create_failure_issue "$LOG_TAIL" "$CURRENT_COMMIT" || log "Failed to create GitHub issue"
        rm -f "$BUILD_OUTPUT"
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
