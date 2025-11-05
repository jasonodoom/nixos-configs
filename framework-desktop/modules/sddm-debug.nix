# Temporary SDDM debugging configuration
# This module temporarily disables complex SDDM settings to isolate the black screen issue
{ config, pkgs, lib, ... }:

{
  # Completely override the themes.nix SDDM configuration for debugging
  services.displayManager.sddm = lib.mkForce {
    enable = true;
    # Use default Qt5 SDDM to eliminate Qt6 as a variable
    wayland.enable = false;
    # Test astronaut theme with Qt5
    theme = "sddm-astronaut-theme";

    # Minimal settings - no custom configurations
    settings = {
      General = {
        DisplayServer = "x11";
        # Enable more verbose logging
        LogLevel = "DEBUG";
      };
      # Restore default user settings - no hiding
      Users = {};
    };
  };

  # Ensure X11 input drivers are properly configured
  services.xserver = {
    enable = true;
    # Explicitly configure input drivers
    libinput = {
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
  };
}