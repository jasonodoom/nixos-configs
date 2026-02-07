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
      if ! ${pkgs.gnupg}/bin/gpg --list-keys jasonodoom >/dev/null 2>&1; then
        echo "Importing GPG public key..."
        ${pkgs.gnupg}/bin/gpg --import "$GPG_KEY_FILE"
      fi

      # Set trust level to ultimate for signature verification
      KEYID=$(${pkgs.gnupg}/bin/gpg --list-keys --with-colons jasonodoom | ${pkgs.gawk}/bin/awk -F: '/^pub/ {print $5}' | head -1)
      echo "$KEYID:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust
    '';
  };

  environment.systemPackages = with pkgs; [
    gnupg
  ];
}
