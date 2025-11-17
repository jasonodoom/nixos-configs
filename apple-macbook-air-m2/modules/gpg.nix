# GPG and YubiKey configuration for theophany (macOS)
{ config, pkgs, lib, ... }:

{
  # GPG agent configuration (macOS doesn't use systemd for GPG agent)
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Create GPG agent config file
  system.activationScripts.gpg-agent-config.text = ''
    USER_HOME="/Users/${config.system.primaryUser}"
    mkdir -p "$USER_HOME/.gnupg"
    cat > "$USER_HOME/.gnupg/gpg-agent.conf" <<EOF
enable-ssh-support
default-cache-ttl 60
max-cache-ttl 120
EOF
    chmod 600 "$USER_HOME/.gnupg/gpg-agent.conf"
    chown ${config.system.primaryUser}:staff "$USER_HOME/.gnupg/gpg-agent.conf"
  '';

  # Import GPG public key from GitHub
  system.activationScripts.import-gpg-key.text = ''
    USER_HOME="/Users/${config.system.primaryUser}"

    # Download GPG public key from GitHub
    GPG_KEY_FILE=${
      builtins.fetchurl {
        url = "https://github.com/jasonodoom.gpg";
        sha256 = "sha256-YHXAcvdLX1F06+9kq+ymQiXJNvyPDckD93V5WUd8Bes=";
      }
    }

    # Import GPG key as the user if not already imported
    if ! sudo -u ${config.system.primaryUser} ${pkgs.gnupg}/bin/gpg --homedir "$USER_HOME/.gnupg" --list-keys jasonodoom >/dev/null 2>&1; then
      echo "Importing GPG public key from GitHub..."
      sudo -u ${config.system.primaryUser} ${pkgs.gnupg}/bin/gpg --homedir "$USER_HOME/.gnupg" --import --trust-model pgp "$GPG_KEY_FILE"
    fi
  '';

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry_mac
    yubikey-personalization
    yubikey-manager
  ];
}
