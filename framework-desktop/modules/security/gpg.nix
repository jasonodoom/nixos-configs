# GPG and smart card configuration for perdurabo
{ config, pkgs, lib, ... }:

{
  # Smart card support for YubiKey
  services.pcscd.enable = true;

  # GPG agent configuration
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
  };

  # Import GPG public key from GitHub for commit signature verification
  # This is a system service so it runs before auto-upgrade even if user isn't logged in
  systemd.services.import-gpg-key = {
    description = "Import GPG public key from GitHub";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "jason";
    };
    path = [ pkgs.gnupg pkgs.curl pkgs.gawk ];
    script = ''
      # Download GPG public key from GitHub (hash-verified)
      GPG_KEY_FILE=${
        builtins.fetchurl {
          url = "https://github.com/jasonodoom.gpg";
          sha256 = "sha256-YHXAcvdLX1F06+9kq+ymQiXJNvyPDckD93V5WUd8Bes=";
        }
      }

      # Import key for jason (used by verify-upgrade-commits)
      echo "Importing GPG public key..."
      gpg --import "$GPG_KEY_FILE" 2>/dev/null || true

      # Set trust level to ultimate for signature verification
      FINGERPRINT=$(gpg --list-keys --with-colons --fingerprint jasonodoom | awk -F: '/^fpr/ {print $10; exit}')
      if [ -n "$FINGERPRINT" ]; then
        echo "$FINGERPRINT:6:" | gpg --import-ownertrust
      fi

      # Import GitHub web-flow signing key for merge commits and set trust
      echo "Importing GitHub web-flow signing key..."
      curl -s https://github.com/web-flow.gpg | gpg --import 2>/dev/null || true

      # Set ultimate trust for GitHub's signing key
      GH_FINGERPRINT=$(gpg --list-keys --with-colons --fingerprint "GitHub <noreply@github.com>" 2>/dev/null | awk -F: '/^fpr/ {print $10; exit}')
      if [ -n "$GH_FINGERPRINT" ]; then
        echo "$GH_FINGERPRINT:6:" | gpg --import-ownertrust
      fi

      echo "GPG public keys imported and trusted"
    '';
  };

  # Timer to periodically check for GPG key updates
  systemd.timers.import-gpg-key = {
    description = "Check for GPG key updates from GitHub";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };
}