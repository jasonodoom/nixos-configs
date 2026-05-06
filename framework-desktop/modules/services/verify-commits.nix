# Verify GPG signatures on commits before auto-upgrade
{ config, pkgs, lib, ... }:

let
  # Trusted signing fingerprints. Auto-upgrade refuses to proceed unless every
  # new commit is signed by one of these.
  trustedFingerprints = [
    "F3DD4A7B465A4EB1823E2EE268CCAF80768A91A5"  # jasonodoom (primary)
    "991349483E19A0E903082F0EC944F52C851F5243"  # jasonodoom (signing subkey)
    "5DE3E0509C47EA3CF04A42D34AEE18F83AFDEB23"  # GitHub web-flow (4AEE18F83AFDEB23)
    "968479A1AFF927E37D1A566BB5690EEEBB952194"  # GitHub web-flow (B5690EEEBB952194)
  ];
in
{
  systemd.services.verify-upgrade-commits = {
    description = "Verify GPG signatures on commits before auto-upgrade";
    before = [ "nixos-upgrade.service" ];
    requiredBy = [ "nixos-upgrade.service" ];
    after = [ "network-online.target" "import-gpg-key.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "jason";
      StateDirectory = "verify-upgrade-commits";
    };
    path = [ pkgs.git pkgs.gnupg pkgs.gh pkgs.gawk ];
    script = ''
      set -euo pipefail

      REPO_URL="https://github.com/jasonodoom/nixos-configs.git"
      WORK_DIR=$(mktemp -d)
      HOSTNAME="perdurabo"
      STATE_FILE="$STATE_DIRECTORY/last-verified"
      TRUSTED_FPS="${lib.concatStringsSep " " trustedFingerprints}"

      cleanup() { rm -rf "$WORK_DIR"; }
      trap cleanup EXIT

      create_failure_issue() {
        local message="$1"
        local commit="$2"

        gh issue create \
          --repo jasonodoom/nixos-configs \
          --title "auto-upgrade signature check failed on $HOSTNAME ($(date +%Y-%m-%d))" \
          --body "Auto-upgrade refused to proceed on $HOSTNAME.

      **Commit:** $commit
      **Time:** $(date)

      **Reason:**
      \`\`\`
      $message
      \`\`\`" \
          --assignee jasonodoom || echo "Failed to create GitHub issue"
      }

      git clone --depth 50 "$REPO_URL" "$WORK_DIR" 2>/dev/null
      cd "$WORK_DIR"
      NEW_HEAD=$(git rev-parse HEAD)

      # Determine which commits to verify: everything since the last verified
      # rev, or the full cloned history on first run / stale state.
      if [ -f "$STATE_FILE" ]; then
        LAST=$(cat "$STATE_FILE")
        if git rev-parse --verify "$LAST^{commit}" >/dev/null 2>&1; then
          COMMITS=$(git log --pretty=format:%H --reverse "$LAST..HEAD" 2>/dev/null || true)
        else
          COMMITS=$(git log --pretty=format:%H --reverse)
        fi
      else
        COMMITS=$(git log --pretty=format:%H --reverse)
      fi

      if [ -z "$COMMITS" ]; then
        echo "No new commits since last verification"
        exit 0
      fi

      for commit in $COMMITS; do
        RAW=$(git verify-commit --raw "$commit" 2>&1 || true)
        FPR=$(echo "$RAW" | awk '/^\[GNUPG:\] VALIDSIG / {print $3; exit}')
        SHORT=$(git rev-parse --short "$commit")

        if [ -z "$FPR" ]; then
          create_failure_issue "Commit $SHORT has no valid GPG signature.

      $RAW" "$SHORT"
          exit 1
        fi

        TRUSTED=0
        for tfpr in $TRUSTED_FPS; do
          if [ "$FPR" = "$tfpr" ]; then
            TRUSTED=1
            break
          fi
        done

        if [ "$TRUSTED" = "0" ]; then
          create_failure_issue "Commit $SHORT signed by untrusted key $FPR.

      Trusted fingerprints: $TRUSTED_FPS" "$SHORT"
          exit 1
        fi
      done

      echo "$NEW_HEAD" > "$STATE_FILE"
      echo "Verified $(echo "$COMMITS" | wc -l) commit(s); upgrade can proceed"
    '';
  };

  systemd.services.nixos-upgrade-failure-notify = {
    description = "Notify on nixos-upgrade failure";
    after = [ "nixos-upgrade.service" ];
    bindsTo = [ "nixos-upgrade.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "jason";
    };
    script = ''
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

  systemd.services.nixos-upgrade.serviceConfig.OnFailure = [ "nixos-upgrade-failure-notify.service" ];
}
