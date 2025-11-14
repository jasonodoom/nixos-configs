# Power management configuration for Framework Desktop
{ config, pkgs, lib, ... }:

{
  # Configure systemd-logind power button behavior for desktop
  services.logind = {
    # Let GNOME handle the power button instead of systemd
    powerKey = "ignore";
    # Long press for emergency shutdown
    powerKeyLongPress = "poweroff";
  };

  # Configure GNOME to show power dialog when power button is pressed
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/settings-daemon/plugins/power" = {
        # Show interactive dialog with shutdown/reboot/suspend options
        power-button-action = "interactive";
      };

      # Ensure logout prompts are enabled
      "org/gnome/SessionManager" = {
        logout-prompt = true;
      };
    };
  }];
}