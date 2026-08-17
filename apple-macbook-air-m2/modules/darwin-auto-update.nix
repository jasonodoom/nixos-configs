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

      # root's git refuses the jason-owned checkout without safe.directory;
      # macOS resolves /var/lib through /private so I allow both spellings.
      GIT="${pkgs.git}/bin/git -c safe.directory=$REPO_DIR -c safe.directory=/private$REPO_DIR"

      log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
      }

      # Alert locally instead of filing a GitHub issue. The issue path
      # needed a PAT in an agenix secret, and when that token expired the
      # alerts died silently: eleven consecutive nightly failures
      # (Aug 2-13, 2026) each got HTTP 401 and nobody heard a thing. A
      # notification on the machine itself has no credential to expire.
      # The details stay in $LOG_FILE; this only has to say "look there".
      # If the Mac is asleep at the scheduled time the update did not run
      # either, so there is no failure to miss.
      notify_failure() {
        local log_content="$1"
        local commit="$2"

        log "Alerting: update failed at commit $commit"

        # Root cannot post to the user's notification center directly;
        # asuser runs osascript inside jason's GUI session.
        /bin/launchctl asuser "$(/usr/bin/id -u jason)" /usr/bin/osascript \
          -e 'display notification "See /var/log/darwin-auto-update.log" with title "darwin-auto-update failed" sound name "Basso"' \
          || log "Notification failed (no GUI session?); details are in $LOG_FILE"
      }

      # set -e aborts before the failure paths below can file an issue;
      # I catch those aborts here so they still surface.
      on_error() {
        log "Update aborted unexpectedly"
        notify_failure "[script] $(tail -50 "$LOG_FILE")" "''${CURRENT_COMMIT:-unknown}" || log "Failed to send failure notification"
        exit 1
      }
      trap on_error ERR

      # Check if on AC power
      if ! /usr/bin/pmset -g ps | grep -q "AC Power"; then
        log "Not on AC power, skipping update"
        exit 0
      fi

      # Pre-flight homebrew + masApps (#77). nix-darwin runs
      # `brew bundle` during activation; if `mas` is missing, the
      # App Store account is not signed in, or one of the masApps
      # IDs is no longer purchasable, the whole rebuild fails.
      # Log the situation up front so the eventual failure issue
      # tells the operator exactly what to fix, and skip the
      # rebuild rather than chasing a known-bad activation.
      if [ -x /opt/homebrew/bin/mas ]; then
        MAS_ACCOUNT=$(/opt/homebrew/bin/mas account 2>&1 || true)
        if echo "$MAS_ACCOUNT" | grep -qi "unexpected argument"; then
          # newer mas dropped the account subcommand
          log "mas has no account subcommand, skipping sign-in check"
        elif [ -z "$MAS_ACCOUNT" ] || echo "$MAS_ACCOUNT" | grep -qiE "not signed in|no account"; then
          log "WARNING: mas account not signed in (output: $MAS_ACCOUNT)"
          log "Skipping rebuild — masApps activation will fail until you sign in to the App Store"
          notify_failure "mas account not signed in. Open App Store, sign in, then re-run darwin-auto-update." "preflight" || log "Failed to send failure notification"
          exit 0
        fi
        log "mas account: $MAS_ACCOUNT"
      else
        log "mas binary not yet installed (first activation will install it)"
      fi

      log "Starting darwin auto-update"

      # Clone or update repo
      if [ -d "$REPO_DIR/.git" ]; then
        log "Updating existing repo"
        cd "$REPO_DIR"
        $GIT fetch origin "$BRANCH"
        $GIT reset --hard "origin/$BRANCH"
      else
        log "Cloning repo"
        rm -rf "$REPO_DIR"
        $GIT clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
        cd "$REPO_DIR"
      fi

      # The script runs under launchd as root; signature verification
      # runs as `su - jason` to pick up jason's gnupg keyring. Without
      # jason ownership on the freshly-written objects, the verify
      # exits with "Permission denied" before gpg ever sees the
      # signature. chown rather than chmod g+rX so the repo stays
      # private (only jason + root can read) even if I move the
      # repo to a private GitHub URL later.
      ${pkgs.coreutils}/bin/chown -R jason:staff "$REPO_DIR"

      CURRENT_COMMIT=$($GIT rev-parse --short HEAD)
      log "Current commit: $CURRENT_COMMIT"

      # Verify commit signature directly in the repo using safe.directory
      log "Verifying commit signature..."
      VERIFY_OUTPUT=$(su - jason -c "${pkgs.git}/bin/git -c safe.directory='$REPO_DIR' -C '$REPO_DIR' verify-commit HEAD 2>&1" || true)
      if ! echo "$VERIFY_OUTPUT" | grep -qE "Good signature from.*(jasonodoom|GitHub)"; then
        log "ERROR: Commit not signed by jasonodoom - aborting update"
        log "Verification output: $VERIFY_OUTPUT"
        notify_failure "Commit signature verification failed. This commit is not signed by jasonodoom.\n\n$VERIFY_OUTPUT" "$CURRENT_COMMIT" || log "Failed to send failure notification"
        exit 1
      fi
      log "Commit signature verified"

      # Hand the repo back to root before the rebuild. The chown to jason
      # exists only so the su-based verify above can use jason's keyring;
      # leaving it jason-owned makes nix's libgit2 refuse the git+file
      # flake fetch as root ("not owned by current user", code 7) — which
      # silently failed every nightly run from Aug 2 to Aug 13, 2026.
      ${pkgs.coreutils}/bin/chown -R root:wheel "$REPO_DIR"

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
        # #77 classify the failure so the issue title points at the
        # right culprit. brew/mas failures are common operator-
        # actionable cases (App Store re-auth, masApp removed,
        # cask name changed); a tagged title lets the operator
        # triage at a glance instead of opening every nightly
        # issue blind.
        if echo "$LOG_TAIL" | grep -qE "mas (install|download).*(fail|error)|brew bundle.*(fail|error)|cask.*not found"; then
          ISSUE_PREFIX="[homebrew]"
        else
          ISSUE_PREFIX="[rebuild]"
        fi
        notify_failure "$ISSUE_PREFIX $LOG_TAIL" "$CURRENT_COMMIT" || log "Failed to send failure notification"
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
