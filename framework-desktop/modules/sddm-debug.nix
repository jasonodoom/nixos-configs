# Temporary SDDM debugging configuration
# This module tests astronaut theme with proper packages installed
{ config, pkgs, lib, ... }:

{
  # Install astronaut theme manually like the working commit
  environment.systemPackages = [
    # Manual astronaut theme installation (like working commit eb5f242)
    (pkgs.stdenv.mkDerivation {
      name = "sddm-astronaut-theme";
      src = pkgs.fetchFromGitHub {
        owner = "Keyitdev";
        repo = "sddm-astronaut-theme";
        rev = "468a100460d5feaa701c2215c737b55789cba0fc";
        sha256 = "sha256-L+5xoyjX3/nqjWtMRlHR/QfAXtnICyGzxesSZexZQMA=";
      };
      installPhase = ''
        mkdir -p $out/share/sddm/themes/sddm-astronaut-theme
        cp -R * $out/share/sddm/themes/sddm-astronaut-theme/
      '';
    })

    # Qt5 packages only (to avoid Qt dependency conflicts with Qt5 SDDM)
    pkgs.qt5.qtgraphicaleffects
    pkgs.qt5.qtquickcontrols2
    pkgs.qt5.qtsvg
    pkgs.qt5.qtmultimedia
  ];

  # Override SDDM configuration - FORCE Qt5 SDDM for astronaut theme compatibility
  services.displayManager.sddm = lib.mkForce {
    enable = true;

    # FORCE Qt5 SDDM package (astronaut theme expects sddm-greeter, not sddm-greeter-qt6)
    package = pkgs.libsForQt5.sddm;

    wayland.enable = false;
    theme = "sddm-astronaut-theme";

    # Settings like working commit eb5f242
    settings = {
      General = {
        DisplayServer = "x11";
        # Enable more verbose logging
        LogLevel = "DEBUG";
      };
      Theme = {
        Current = "sddm-astronaut-theme";
        ThemeDir = "/run/current-system/sw/share/sddm/themes";
        CursorTheme = "breeze_cursors";
        Font = "JetBrains Mono,12,-1,0,50,0,0,0,0,0";
      };
      # Hide usernames for security (like original themes.nix)
      Users = {
        HideUsers = "*";
        HideShells = "/bin/false,/usr/bin/nologin";
        RememberLastUser = false;
      };
    };
  };

  # Custom theme configuration like working commit eb5f242
  environment.etc."sddm.conf.d/theme.conf".text = ''
    [Theme]
    Current=sddm-astronaut-theme
    ThemeDir=/run/current-system/sw/share/sddm/themes
    CursorTheme=breeze_cursors
    Font=JetBrains Mono,12,-1,0,50,0,0,0,0,0
  '';

  # Ensure X11 and input drivers are properly configured
  services.xserver.enable = true;

  services.libinput = {
    enable = true;
    mouse = {
      accelProfile = "flat";
      accelSpeed = "0";
    };
    touchpad = {
      accelProfile = "flat";
      accelSpeed = "0";
    };
  };
}