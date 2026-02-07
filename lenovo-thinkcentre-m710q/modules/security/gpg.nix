# GPG configuration for congo server
{ config, pkgs, lib, ... }:

{
  # Import GPG public key from GitHub for commit signature verification
  systemd.services.import-gpg-key = {
    description = "Import GPG public key from GitHub";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Download GPG public key from GitHub (hash-verified)
      GPG_KEY_FILE=${
        builtins.fetchurl {
          url = "https://github.com/jasonodoom.gpg";
          sha256 = "sha256-YHXAcvdLX1F06+9kq+ymQiXJNvyPDckD93V5WUd8Bes=";
        }
      }

      # Import key for root (used by auto-upgrade)
      echo "Importing GPG public key..."
      ${pkgs.gnupg}/bin/gpg --import "$GPG_KEY_FILE" 2>/dev/null || true

      # Set trust level to ultimate for signature verification
      # Get fingerprint and set ultimate trust (6)
      FINGERPRINT=$(${pkgs.gnupg}/bin/gpg --list-keys --with-colons --fingerprint jasonodoom | ${pkgs.gawk}/bin/awk -F: '/^fpr/ {print $10; exit}')
      if [ -n "$FINGERPRINT" ]; then
        echo "$FINGERPRINT:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust
      fi

      # Import GitHub web-flow signing key for merge commits and set trust
      echo "Importing GitHub web-flow signing key..."
      ${pkgs.curl}/bin/curl -s https://github.com/web-flow.gpg | ${pkgs.gnupg}/bin/gpg --import 2>/dev/null || true

      # Set ultimate trust for GitHub's signing key
      GH_FINGERPRINT=$(${pkgs.gnupg}/bin/gpg --list-keys --with-colons --fingerprint "GitHub <noreply@github.com>" 2>/dev/null | ${pkgs.gawk}/bin/awk -F: '/^fpr/ {print $10; exit}')
      if [ -n "$GH_FINGERPRINT" ]; then
        echo "$GH_FINGERPRINT:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust
      fi

      echo "GPG public keys imported and trusted"
    '';
  };

  environment.systemPackages = with pkgs; [
    gnupg
  ];
}
