# Verify GPG signatures on commits before auto-upgrade
{ config, pkgs, lib, ... }:

{
  # Systemd service to verify commit signatures before upgrade
  systemd.services.verify-upgrade-commits = {
    description = "Verify GPG signatures on commits before auto-upgrade";
    before = [ "nixos-upgrade.service" ];
    requiredBy = [ "nixos-upgrade.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "jason";
    };
    script = ''
      set -euo pipefail

      REPO_URL="git@github-deploy.com:jasonodoom/nixos-configs.git"
      WORK_DIR=$(mktemp -d)
      TRUSTED_KEY="jasonodoom"

      cleanup() {
        rm -rf "$WORK_DIR"
      }
      trap cleanup EXIT

      echo "Cloning repo to verify signatures..."
      ${pkgs.git}/bin/git clone --depth 50 "$REPO_URL" "$WORK_DIR" 2>/dev/null

      cd "$WORK_DIR"

      echo "Verifying HEAD commit signature..."
      if ! ${pkgs.git}/bin/git verify-commit HEAD 2>&1 | grep -q "Good signature from.*$TRUSTED_KEY"; then
        echo "ERROR: HEAD commit is not signed by $TRUSTED_KEY"
        echo "Aborting upgrade for security"
        exit 1
      fi

      echo "Commit signature verified - upgrade can proceed"
    '';
  };
}
