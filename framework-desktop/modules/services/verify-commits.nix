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

      REPO_URL="https://github.com/jasonodoom/nixos-configs.git"
      WORK_DIR=$(mktemp -d)
      TRUSTED_KEY="jasonodoom"
      HOSTNAME="perdurabo"

      cleanup() {
        rm -rf "$WORK_DIR"
      }
      trap cleanup EXIT

      create_failure_issue() {
        local message="$1"
        local commit="$2"

        ${pkgs.gh}/bin/gh issue create \
          --repo jasonodoom/nixos-configs \
          --title "auto-upgrade failed on $HOSTNAME ($(date +%Y-%m-%d))" \
          --body "The scheduled auto-upgrade failed on $HOSTNAME.

**Commit:** $commit
**Time:** $(date)

**Error:**
\`\`\`
$message
\`\`\`" \
          --assignee jasonodoom || echo "Failed to create GitHub issue"
      }

      echo "Cloning repo to verify signatures..."
      ${pkgs.git}/bin/git clone --depth 50 "$REPO_URL" "$WORK_DIR" 2>/dev/null

      cd "$WORK_DIR"
      CURRENT_COMMIT=$(${pkgs.git}/bin/git rev-parse --short HEAD)

      echo "Verifying HEAD commit signature..."
      VERIFY_OUTPUT=$(${pkgs.git}/bin/git verify-commit HEAD 2>&1 || true)

      if ! echo "$VERIFY_OUTPUT" | grep -qE "Good signature from.*(jasonodoom|GitHub)"; then
        echo "ERROR: HEAD commit is not signed by jasonodoom or GitHub"
        create_failure_issue "Commit signature verification failed. This commit is not signed by jasonodoom or GitHub.

$VERIFY_OUTPUT" "$CURRENT_COMMIT"
        exit 1
      fi

      echo "Commit signature verified - upgrade can proceed"
    '';
  };

  # Create issue if nixos-upgrade itself fails
  systemd.services.nixos-upgrade-failure-notify = {
    description = "Notify on nixos-upgrade failure";
    after = [ "nixos-upgrade.service" ];
    bindsTo = [ "nixos-upgrade.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "jason";
    };
    script = ''
      # Only runs if nixos-upgrade fails (due to OnFailure)
      HOSTNAME="perdurabo"

      ${pkgs.gh}/bin/gh issue create \
        --repo jasonodoom/nixos-configs \
        --title "nixos-upgrade failed on $HOSTNAME ($(date +%Y-%m-%d))" \
        --body "The scheduled nixos-upgrade service failed on $HOSTNAME.

**Time:** $(date)

Check journalctl for details:
\`\`\`
journalctl -u nixos-upgrade.service -n 100
\`\`\`" \
        --assignee jasonodoom || echo "Failed to create GitHub issue"
    '';
  };

  # Hook the failure notification
  systemd.services.nixos-upgrade.serviceConfig.OnFailure = [ "nixos-upgrade-failure-notify.service" ];
}
