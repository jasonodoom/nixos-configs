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
    kdePackages.plasma-workspace  # includes plasmashell
    kdePackages.kwin
    kdePackages.plasma-activities
    kdePackages.krunner
    kdePackages.kscreenlocker
    kdePackages.kglobalaccel

    # Additional theming tools
    kdePackages.plasma-browser-integration
    kdePackages.kdeconnect-kde

    # Reset script for Plasma configuration
    (writeShellScriptBin "reset-plasma" ''
      echo "Resetting Plasma configuration..."
      rm -rf ~/.config/plasma*
      rm -rf ~/.config/kde*
      rm -rf ~/.local/share/kactivitymanagerd
      rm -rf ~/.cache/plasma*
      echo "Plasma configuration reset. Please log out and log back in."
    '')

    # Debug script for Plasma issues
    (writeShellScriptBin "debug-plasma" ''
      echo "=== Plasma Debug Information ==="
      echo "Current session: $XDG_CURRENT_DESKTOP"
      echo "Session type: $XDG_SESSION_TYPE"
      echo ""
      echo "=== Running Plasma processes ==="
      pgrep -l plasma || echo "No plasma processes running"
      pgrep -l kwin || echo "No kwin processes running"
      echo ""
      echo "=== Recent Plasma logs ==="
      journalctl --user -u plasma* --since "5 minutes ago" --no-pager -n 20
    '')
  ];

  # Minimal KDE configuration - configure themes manually to avoid conflict

  # Ensure proper session configuration (can be overridden by other modules)
  services.displayManager.defaultSession = lib.mkDefault "plasma";
}