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

  # Import GPG public key from GitHub for YubiKey use
  systemd.user.services.import-gpg-key = {
    description = "Import GPG public key from GitHub";
    wantedBy = [ "default.target" ];
    after = [ "network-online.target" "graphical-session.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;  # Allow re-running for key updates
      Restart = "on-failure";
      RestartSec = "30s";
      ExecStart = "${pkgs.writeShellScript "import-gpg-key" ''
        # Wait for network connectivity
        until ${pkgs.curl}/bin/curl -s --max-time 10 https://github.com >/dev/null 2>&1; do
          echo "Waiting for GitHub connectivity..."
          sleep 5
        done

        # Download GPG public key from GitHub for manual verification
        GPG_KEY_FILE=${
          builtins.fetchurl {
            url = "https://github.com/jasonodoom.gpg";
            sha256 = "sha256-YHXAcvdLX1F06+9kq+ymQiXJNvyPDckD93V5WUd8Bes=";
          }
        }

        # Check if key is already imported (avoid duplicates)
        if ! ${pkgs.gnupg}/bin/gpg --list-keys jasonodoom >/dev/null 2>&1; then
          echo "Importing GPG public key from GitHub..."
          ${pkgs.gnupg}/bin/gpg --import --trust-model pgp "$GPG_KEY_FILE"
        else
          echo "GPG key already imported, checking for updates..."
          ${pkgs.gnupg}/bin/gpg --import --trust-model pgp "$GPG_KEY_FILE"
        fi

        # Get the key ID and set ultimate trust for signature verification
        KEYID=$(${pkgs.gnupg}/bin/gpg --list-keys --with-colons jasonodoom | ${pkgs.gawk}/bin/awk -F: '/^pub/ {print $5}' | head -1)
        echo "$KEYID:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust

        echo "GPG public key imported and trusted"
      ''}";
    };
  };

  # Timer to periodically check for GPG key updates
  systemd.user.timers.import-gpg-key = {
    description = "Check for GPG key updates from GitHub";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };
}