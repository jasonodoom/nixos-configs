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

  # SHAs to skip during signature verification. Use sparingly — only for
  # historical unsigned commits we cannot retroactively sign (e.g. early
  # auto-PR workflow runs that committed without going through the GraphQL
  # signed-commit path). New unsigned commits should still be rejected.
  # All 10 entries are pre-fa2942d auto-PR / auto-update bot commits that
  # predate signed-commit support. The workflow fix in fa2942d means new
  # bot commits are signed via web-flow, so this list should not need to grow.
  exemptCommits = [
    "17765a9d3a1d3f4f5f2c0494f03029a71cf288f2"  # 2025-12-19 chore: update flake.lock files
    "2bae9b825803ff61cc2e21737a26a231b22745fd"  # 2025-12-20 chore: update flake.lock files
    "a918032f515efd21b08d114a4c70d2bab5866ae3"  # 2026-03-02 chore: update flake.lock files
    "badd2f4e8c145b636f384fad26287336eabdbd61"  # 2026-03-16 chore: update flake.lock files
    "f3908a4bf73bd1836ce6da6df240747e279474d0"  # 2026-03-18 chore: update flake.lock files
    "63bd709a8841227bf7f5b6a3489e5c0013e7a0f1"  # 2026-04-12 chore: update flake.lock files
    "d96f35fc378e5224d63ce02ca1e4797dec5aca89"  # 2026-04-12 chore: update flake.lock files
    "f7d199a761ec689d0ffa960f852b8f4eb1eba6c8"  # 2026-04-21 chore: update flake.lock files
    "4df13208ce74c05ce34ec46289834227e82c2922"  # 2026-04-22 chore: update flake.lock files
    "b5bf556a74567d91016bf6cdb641e1dcd3d53730"  # 2026-05-08 Update Claude Code to 2.1.133
    "256d43aef93bbe290d2252bad04238ef759c7d02"  # 2026-06-01 Update Claude Code to 2.1.156 (last unsigned auto-PR commit before 68e19b4 fixed signing)
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
      EXEMPT_SHAS="${lib.concatStringsSep " " exemptCommits}"

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
        SHORT=$(git rev-parse --short "$commit")

        EXEMPT=0
        for esha in $EXEMPT_SHAS; do
          if [ "$commit" = "$esha" ]; then
            EXEMPT=1
            break
          fi
        done
        if [ "$EXEMPT" = "1" ]; then
          echo "Skipping signature check for exempt commit $SHORT"
          continue
        fi

        RAW=$(git verify-commit --raw "$commit" 2>&1 || true)
        FPR=$(echo "$RAW" | awk '/^\[GNUPG:\] VALIDSIG / {print $3; exit}')

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
