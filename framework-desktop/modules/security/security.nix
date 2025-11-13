# Security configuration
{ config, pkgs, lib, ... }:

{
  # Prevent password changes except through configuration
  users.mutableUsers = false;

  # Enable doas instead of sudo
  security.doas.enable = true;
  security.sudo.enable = false;

  # Configure doas
  security.doas.extraRules = [{
    users = [ "jason" ];
    keepEnv = true;
    persist = true;  # Remember authentication for a session
  }];

  # YubiKey support
  # https://nixos.wiki/wiki/Yubikey
  services.udev.packages = with pkgs; [
    yubikey-personalization  # Required for YubiKey udev rules
    android-udev-rules
  ];

  services.udev.extraRules = ''
    # Yubico YubiKey
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0200|0402|0403|0406|0407|0410", TAG+="uaccess"
    # Teensy rules for the Ergodox EZ
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"
  '';

  # GPG configuration
  programs.gnupg.agent = {
    enable = true;
  };

  # GPG configuration file
  environment.etc."skel/.gnupg/gpg.conf".text = ''
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
  '';

  # Ensure GPG config is copied to user's home directory
  systemd.user.services.gpg-config = {
    description = "Setup GPG configuration";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p $HOME/.gnupg && cp /etc/skel/.gnupg/gpg.conf $HOME/.gnupg/gpg.conf && chmod 600 $HOME/.gnupg/gpg.conf'";
    };
  };

  # Smartcard support
  services.pcscd.enable = true;

  # YubiKey PAM configuration
  security.pam.yubico = {
    enable = true;
    debug = false;
    mode = "challenge-response";
    id = [ "5252959" ];  # YubiKey serial number
  };

  # Automated YubiKey challenge-response setup
  systemd.services.yubikey-setup = {
    description = "Set up YubiKey challenge-response authentication";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];  # Wait for USB devices
    wants = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Don't restart on failure - YubiKey may not be present
      TimeoutStartSec = "30s";
      ExecStart = "${pkgs.writeShellScript "yubikey-setup" ''
        # Create yubico directory
        mkdir -p /etc/yubico

        # Check if any YubiKey is present first
        echo "Checking for YubiKey..."
        if ! ${pkgs.yubikey-manager}/bin/ykman list >/dev/null 2>&1; then
          echo "No YubiKey detected, skipping setup"
          exit 0  # Success - no YubiKey present, nothing to do
        fi

        # Get YubiKey serial
        SERIAL=$(${pkgs.yubikey-manager}/bin/ykman list --serials 2>/dev/null | head -1 || echo "none")
        echo "Found YubiKey with serial: $SERIAL"

        # If it's our expected YubiKey, configure it
        if [ "$SERIAL" = "5252959" ]; then
          # Check if challenge-response is already configured
          if ${pkgs.yubikey-manager}/bin/ykman otp info 2>/dev/null | grep -q "Slot 2.*configured"; then
            echo "YubiKey challenge-response already configured"
          else
            echo "Setting up YubiKey challenge-response for serial 5252959..."
            echo "Please touch your YubiKey when it blinks..."
            ${pkgs.yubikey-manager}/bin/ykman otp chalresp --touch --generate 2
            echo "YubiKey challenge-response setup completed"
          fi
        else
          echo "YubiKey serial $SERIAL does not match expected 5252959, skipping setup"
        fi
      ''}";
    };
  };

  security.pam.services = {
    # Enable YubiKey for doas
    # Works over SSH with pcscd socket forwarding
    doas.yubicoAuth = true;

    login = {
      enableGnomeKeyring = true;
      yubicoAuth = true;
    };

    # Enable YubiKey for SDDM
    sddm.yubicoAuth = true;
  };

  # GNOME Keyring
  services.gnome.gnome-keyring.enable = true;

  # Seat management for Wayland (fixes libseat errors)
  services.seatd.enable = true;

  # Security packages
  environment.systemPackages = with pkgs; [
    # YubiKey tools
    yubikey-manager
    yubioath-flutter       # Replacement for deprecated yubikey-manager-qt
    yubikey-personalization
    yubikey-personalization-gui
    yubico-pam

    # GPG tools
    pinentry-curses
    pinentry-qt

    # Password management
    pass

    # Network tools
    nmap
    wireshark
    magic-wormhole
  ];
}