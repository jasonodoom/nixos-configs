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
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "import-gpg-key" ''
        # Download GPG public key from GitHub for manual verification
        GPG_KEY_FILE=${
          builtins.fetchurl {
            url = "https://github.com/jasonodoom.gpg";
            sha256 = "sha256-YHXAcvdLX1F06+9kq+ymQiXJNvyPDckD93V5WUd8Bes=";
          }
        }

        # Import without automatic trust
        ${pkgs.gnupg}/bin/gpg --import --trust-model pgp "$GPG_KEY_FILE"

        # Get the key ID from the imported key
        KEYID=$(${pkgs.gnupg}/bin/gpg --list-keys --with-colons jasonodoom | ${pkgs.gawk}/bin/awk -F: '/^pub/ {print $5}' | head -1)

        echo "GPG public key imported from GitHub - manual verification required"
        echo "To trust the key, run: gpg --edit-key $KEYID trust"
      ''}";
    };
  };
}