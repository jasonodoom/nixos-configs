# Security configuration
{ config, pkgs, lib, ... }:

{
  # Enable doas instead of sudo
  security.doas.enable = true;
  security.sudo.enable = false;

  # Configure doas
  security.doas.extraRules = [{
    users = [ "jason" ];
    keepEnv = true;
    persist = true;
  }];

  # YubiKey support
  services.udev.packages = with pkgs; [
    yubikey-personalization
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
  programs.ssh.startAgent = false;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Smartcard support
  services.pcscd.enable = true;

  # YubiKey PAM
  security.pam.yubico = {
    enable = true;
    debug = true;
    mode = "challenge-response";
  };

  security.pam.services = {
    sudo.yubicoAuth = true;
    login = {
      enableGnomeKeyring = true;
      u2fAuth = true;
    };
    sudo.u2fAuth = true;
    lightdm.u2fAuth = true;
  };

  # GNOME Keyring
  services.gnome.gnome-keyring.enable = true;

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