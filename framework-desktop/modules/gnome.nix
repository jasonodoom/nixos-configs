# GNOME Desktop Environment Configuration
{ config, pkgs, lib, ... }:

let
  # Configuration options for easier switching
  useWayland = true;  # Set to false to use X11 instead
  useGnomeAsDefault = true;  # Set to false to disable GNOME and use alternative DE
in

{
  # Services configuration
  services = {
    # Enable X server (always available)
    xserver = {
      enable = lib.mkDefault true;
      desktopManager.gnome.enable = useGnomeAsDefault;

      # Use GDM display manager when GNOME is enabled
      displayManager.gdm = lib.mkIf useGnomeAsDefault {
        enable = true;
        wayland = useWayland;
        settings = {
          daemon = {
            # Security: Don't show user list, require manual username entry
            TimedLoginEnable = false;
            AutomaticLoginEnable = false;
          };
          greeter = {
            # Security: Hide user list, require manual username entry
            "disable-user-list" = true;
          };
          security = {
            DisallowTCP = true;
            AllowRemoteAutoLogin = false;
          };
        };
      };
    };

    # Set GNOME as default session only when enabled
    displayManager.defaultSession = lib.mkIf useGnomeAsDefault (
      if useWayland then "gnome" else "gnome-xorg"
    );

    # GNOME-specific services (only when GNOME is enabled)
    gnome = lib.mkIf useGnomeAsDefault {
      core-developer-tools.enable = false;  # Disable by default (GNOME Builder, Devhelp, etc.)
      games.enable = false;  # Disable GNOME games
      core-apps.enable = true;  # Keep core utilities like file manager
      gnome-keyring.enable = true;  # Credential management
    };

    # Required services for GNOME (conditional)
    gvfs.enable = lib.mkIf useGnomeAsDefault true;
    tumbler.enable = lib.mkIf useGnomeAsDefault true;

    # D-Bus service (shared across desktop environments)
    dbus.enable = lib.mkDefault true;
  };

  # Configure GDM background image
  systemd.services.gdm-background = lib.mkIf useGnomeAsDefault {
    description = "Set GDM background image";
    wantedBy = [ "display-manager.service" ];
    before = [ "display-manager.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "gdm";
      ExecStart = pkgs.writeShellScript "set-gdm-background" ''
        # Wait for GDM to be ready
        sleep 2

        # Set GDM background to login wallpaper
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.background picture-uri "file:///run/current-system/sw/share/backgrounds/nixos/login-background.png"
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.background picture-uri-dark "file:///run/current-system/sw/share/backgrounds/nixos/login-background.png"
      '';
    };
  };

  # Install GNOME packages only when GNOME is enabled
  environment.systemPackages = lib.optionals useGnomeAsDefault (with pkgs; [
    # GNOME Extensions
    gnomeExtensions.just-perfection
    gnomeExtensions.dash-to-dock
    gnomeExtensions.appindicator
    gnomeExtensions.caffeine
    gnomeExtensions.user-themes
    gnomeExtensions.gsconnect
    gnomeExtensions.blur-my-shell
    gnomeExtensions.vitals
    gnomeExtensions.sound-output-device-chooser
    gnomeExtensions.clipboard-indicator

    # GNOME apps and utilities
    gnome-tweaks
    dconf-editor
    gnome-extension-manager

    # Terminal applications
    gnome-terminal

    # Wallpapers (shared across desktop environments)
    (pkgs.stdenv.mkDerivation {
      name = "nixos-wallpapers";
      src = ../wallpapers;
      installPhase = ''
        mkdir -p $out/share/backgrounds/nixos
        cp *.png $out/share/backgrounds/nixos/
      '';
    })
  ]) ++ (with pkgs; [
    # Development tools (always available regardless of DE)
    vscode
    git
  ]);

  # Configure GNOME settings via dconf (only when GNOME is enabled)
  programs.dconf.enable = lib.mkDefault useGnomeAsDefault;

  # Set default applications and wallpaper (only for GNOME)
  programs.dconf.profiles.user.databases = lib.mkIf useGnomeAsDefault [{
    settings = {
      # Set ghostty as default terminal application
      "org/gnome/desktop/applications/terminal" = {
        exec = "ghostty";
      };

      # Set firefox as default browser
      "org/gnome/desktop/applications/browser" = {
        exec = "firefox";
        exec-arg = "%s";
      };

      # Set thunderbird as default email client
      "org/gnome/desktop/applications/mail" = {
        exec = "thunderbird";
        exec-arg = "%s";
      };

      # Set desktop wallpaper as background
      "org/gnome/desktop/background" = {
        picture-uri = "file:///run/current-system/sw/share/backgrounds/nixos/nix-wallpaper-binary-black.png";
        picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/nixos/nix-wallpaper-binary-black.png";
      };
    };
  }];

  # GNOME-specific system configuration (only when GNOME is enabled)
  programs.gnome-disks.enable = lib.mkDefault useGnomeAsDefault;
  programs.seahorse.enable = lib.mkDefault useGnomeAsDefault;  # Passwords and Keys
  programs.file-roller.enable = lib.mkDefault useGnomeAsDefault;  # Archive manager

  # XDG portals for GNOME (only when GNOME is enabled)
  xdg.portal = lib.mkIf useGnomeAsDefault {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  # Fonts for GNOME (conditional, with GNOME-specific defaults)
  fonts = lib.mkIf useGnomeAsDefault {
    packages = with pkgs; [
      cantarell-fonts  # GNOME default font
      dejavu_fonts
      liberation_ttf
      source-code-pro
      jetbrains-mono
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "DejaVu Serif" ];
        sansSerif = [ "Cantarell" "DejaVu Sans" ];
        monospace = [ "JetBrains Mono" "Source Code Pro" ];
      };
    };
  };

  # Network management (using mkDefault to allow override)
  networking.networkmanager.enable = lib.mkDefault true;
  programs.nm-applet.enable = lib.mkDefault useGnomeAsDefault;

  # Enable GNOME settings in environment variables (only when GNOME is enabled)
  environment.sessionVariables = lib.mkIf useGnomeAsDefault {
    # GNOME-specific environment
    XDG_CURRENT_DESKTOP = "GNOME";
    XDG_SESSION_DESKTOP = "gnome";
    GNOME_SHELL_SESSION_MODE = "user";

    # Wayland environment (conditional based on useWayland setting)
    MOZ_ENABLE_WAYLAND = if useWayland then "1" else "0";
    QT_QPA_PLATFORM = if useWayland then "wayland" else "xcb";
    GDK_BACKEND = if useWayland then "wayland" else "x11";
  };

  # Configure GNOME power settings
  systemd.user.services.gnome-power-settings = lib.mkIf useGnomeAsDefault {
    description = "Configure GNOME power management for desktop";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "gnome-power-settings" ''
        # Wait for GNOME to be ready
        sleep 5

        # Set screen lock and screensaver (1 minute idle, immediate lock)
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.session idle-delay 60
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.screensaver idle-activation-enabled true
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.screensaver lock-enabled true
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.screensaver lock-delay 0

        # Set monitor sleep (15 minutes, don't suspend system - desktop with UPS)
        ${pkgs.glib}/bin/gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 900
        ${pkgs.glib}/bin/gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

        # Enable screen dimming
        ${pkgs.glib}/bin/gsettings set org.gnome.settings-daemon.plugins.power idle-dim true
        ${pkgs.glib}/bin/gsettings set org.gnome.settings-daemon.plugins.power idle-brightness 30
      '';
    };
  };

  # Security (shared across desktop environments)
  security.polkit.enable = lib.mkDefault true;
  programs.gnupg.agent = {
    enable = lib.mkDefault true;
    enableSSHSupport = lib.mkDefault true;
  };

  # Exclude specific GNOME packages (only when GNOME is enabled)
  environment.gnome.excludePackages = lib.mkIf useGnomeAsDefault (with pkgs; [
    epiphany  # GNOME web browser (use Firefox)
    geary  # Email (use Thunderbird)
    tali  # Poker game
    iagno  # Go game
    hitori  # Sudoku game
    atomix  # Puzzle game
  ]);
}