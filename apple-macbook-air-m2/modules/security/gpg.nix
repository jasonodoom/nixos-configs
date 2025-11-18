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

  # Create GPG config file
  system.activationScripts.gpg-config.text = ''
    USER_HOME="/Users/${config.system.primaryUser}"
    mkdir -p "$USER_HOME/.gnupg"
    cat > "$USER_HOME/.gnupg/gpg.conf" <<'EOF'
auto-key-locate keyserver
keyserver-options no-honor-keyserver-url
personal-cipher-preferences AES256 AES192 AES CAST5
personal-digest-preferences SHA512 SHA384 SHA256 SHA224
default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed
cert-digest-algo SHA512
s2k-cipher-algo AES256
s2k-digest-algo SHA512
charset utf-8
fixed-list-mode
no-comments
no-emit-version
keyid-format 0xlong
list-options show-uid-validity
verify-options show-uid-validity
with-fingerprint
use-agent
require-cross-certification
EOF
    chmod 600 "$USER_HOME/.gnupg/gpg.conf"
    chown ${config.system.primaryUser}:staff "$USER_HOME/.gnupg/gpg.conf"
  '';

  # Import GPG public key from GitHub with hash verification
  system.activationScripts.import-gpg-key.text = ''
    USER_HOME="/Users/${config.system.primaryUser}"

    # Download GPG public key from GitHub (hash-verified)
    GPG_KEY_FILE=${
      builtins.fetchurl {
        url = "https://github.com/jasonodoom.gpg";
        sha256 = "sha256-YHXAcvdLX1F06+9kq+ymQiXJNvyPDckD93V5WUd8Bes=";
      }
    }

    # Check if key is already imported (avoid duplicates)
    if ! sudo -u ${config.system.primaryUser} ${pkgs.gnupg}/bin/gpg --homedir "$USER_HOME/.gnupg" --list-keys jasonodoom >/dev/null 2>&1; then
      echo "Importing GPG public key from GitHub..."
      sudo -u ${config.system.primaryUser} ${pkgs.gnupg}/bin/gpg --homedir "$USER_HOME/.gnupg" --import --trust-model pgp "$GPG_KEY_FILE"
    else
      echo "GPG key already imported, checking for updates..."
      sudo -u ${config.system.primaryUser} ${pkgs.gnupg}/bin/gpg --homedir "$USER_HOME/.gnupg" --import --trust-model pgp "$GPG_KEY_FILE"
    fi

    # Get the key ID from the imported key
    KEYID=$(sudo -u ${config.system.primaryUser} ${pkgs.gnupg}/bin/gpg --homedir "$USER_HOME/.gnupg" --list-keys --with-colons jasonodoom | ${pkgs.gawk}/bin/awk -F: '/^pub/ {print $5}' | head -1)

    echo "GPG public key imported from GitHub - manual verification required"
    echo "To trust the key, run: gpg --edit-key \$KEYID trust"
  '';

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry_mac
  ];
}
