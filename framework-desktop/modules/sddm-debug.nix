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

    # Qt6 packages for rendering
    pkgs.kdePackages.qtsvg
    pkgs.kdePackages.qtmultimedia
    pkgs.kdePackages.qtvirtualkeyboard

    # Critical Qt5 packages (missing from current config)
    pkgs.qt5.qtgraphicaleffects
    pkgs.qt5.qtquickcontrols2
    pkgs.qt5.qtsvg
  ];

  # Override SDDM configuration - use default SDDM (Qt5) like working commit
  services.displayManager.sddm = lib.mkForce {
    enable = true;

    # DO NOT override package - use default Qt5 SDDM like working commit
    # package = pkgs.kdePackages.sddm;

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
      # Restore default user settings - no hiding
      Users = {};
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