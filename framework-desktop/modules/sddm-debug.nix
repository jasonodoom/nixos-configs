# Temporary SDDM debugging configuration
# This module tests astronaut theme with proper packages installed
{ config, pkgs, lib, ... }:

{
  # Install astronaut theme package and Qt6 dependencies
  environment.systemPackages = [
    (pkgs.sddm-astronaut.override {
      embeddedTheme = "astronaut";
      themeConfig = {};
    })
    pkgs.kdePackages.qtmultimedia
    pkgs.kdePackages.qtsvg
  ];

  # Override SDDM configuration with proper astronaut theme setup
  services.displayManager.sddm = lib.mkForce {
    enable = true;

    # Use Qt6 SDDM package for astronaut theme
    package = pkgs.kdePackages.sddm;

    wayland.enable = false;
    theme = "sddm-astronaut-theme";

    # Add Qt6 packages needed for astronaut theme
    extraPackages = [
      pkgs.kdePackages.qtmultimedia
      pkgs.kdePackages.qtsvg
    ];

    # Minimal settings - no custom configurations
    settings = {
      General = {
        DisplayServer = "x11";
        # Enable more verbose logging
        LogLevel = "DEBUG";
      };
      Theme = {
        Current = "sddm-astronaut-theme";
      };
      # Restore default user settings - no hiding
      Users = {};
    };
  };

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