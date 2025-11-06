# KDE Plasma 6 Configuration with MacSonoma Theme
{ config, pkgs, lib, ... }:

{
  # Enable KDE Plasma 6
  services.desktopManager.plasma6.enable = true;

  # KDE applications and theme support
  environment.systemPackages = with pkgs; [
    # KDE Applications
    kdePackages.kate          # Text editor
    kdePackages.dolphin       # File manager
    kdePackages.konsole       # Terminal
    kdePackages.spectacle     # Screenshots
    kdePackages.kscreen       # Display management
    kdePackages.systemsettings # System settings

    # Essential Plasma components
    kdePackages.kactivitymanagerd
    kdePackages.plasma-desktop
    kdePackages.plasma-workspace
    kdePackages.kwin
    kdePackages.plasma-activities
    kdePackages.krunner

    # Additional theming tools
    kdePackages.plasma-browser-integration
    kdePackages.kdeconnect-kde
  ];

  # Minimal KDE configuration - configure themes manually to avoid conflict

  # Add script to reset Plasma configuration if needed
  environment.systemPackages = pkgs.lib.mkAfter [
    (pkgs.writeShellScriptBin "reset-plasma" ''
      echo "Resetting Plasma configuration..."
      rm -rf ~/.config/plasma*
      rm -rf ~/.config/kde*
      rm -rf ~/.local/share/kactivitymanagerd
      rm -rf ~/.cache/plasma*
      echo "Plasma configuration reset. Please log out and log back in."
    '')
  ];

  # Ensure proper session configuration
  services.displayManager.defaultSession = "plasma";
}