# SDDM Theme Configuration Module - Working Astronaut Theme with Qt5
#
# IMPORTANT: This configuration fixes a critical black screen issue with the astronaut theme.
# The issue was that the astronaut theme expects Qt5 SDDM (sddm-greeter binary) but
# Qt6 SDDM provides sddm-greeter-qt6, causing theme incompatibility and black screen
# on mouse movement. Force Qt5 SDDM (libsForQt5.sddm) with Qt5 packages only.
#
{ config, pkgs, lib, ... }:

let
  # Available theme configurations
  themes = {

    # Default astronaut theme (same as hacker for now)
    astronaut-default = {
      name = "sddm-astronaut-theme";
      package = pkgs.stdenv.mkDerivation {
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
      };
      extraPackages = [
        pkgs.qt5.qtgraphicaleffects
        pkgs.qt5.qtquickcontrols2
        pkgs.qt5.qtsvg
        pkgs.qt5.qtmultimedia
        # Cursor theme packages to fix "Could not setup default cursor"
        pkgs.libsForQt5.breeze-qt5
        pkgs.libsForQt5.breeze-icons
      ];
    };

    # Maya theme (built-in)
    maya = {
      name = "maya";
      package = null;
      extraPackages = [];
    };

    # Maldives theme (built-in)
    maldives = {
      name = "maldives";
      package = null;
      extraPackages = [];
    };

    # Astronaut Hacker theme with custom background
    astronaut-hacker = {
      name = "astronaut-hacker";
      package = pkgs.stdenv.mkDerivation {
        name = "astronaut-hacker-theme";
        src = pkgs.fetchFromGitHub {
          owner = "Keyitdev";
          repo = "sddm-astronaut-theme";
          rev = "468a100460d5feaa701c2215c737b55789cba0fc";
          sha256 = "sha256-L+5xoyjX3/nqjWtMRlHR/QfAXtnICyGzxesSZexZQMA=";
        };
        nativeBuildInputs = [ pkgs.gnused ];
        installPhase = ''
          mkdir -p $out/share/sddm/themes/astronaut-hacker
          cp -R * $out/share/sddm/themes/astronaut-hacker/

          # Copy custom background image to Backgrounds directory
          mkdir -p $out/share/sddm/themes/astronaut-hacker/Backgrounds
          cp ${./hyprland/wallpapers/sddm-background.png} $out/share/sddm/themes/astronaut-hacker/Backgrounds/custom-background.png

          # Update theme.conf to use custom background
          sed -i 's|Background=.*|Background=Backgrounds/custom-background.png|g' $out/share/sddm/themes/astronaut-hacker/theme.conf
        '';
      };
      extraPackages = [
        pkgs.qt5.qtgraphicaleffects
        pkgs.qt5.qtquickcontrols2
        pkgs.qt5.qtsvg
        pkgs.qt5.qtmultimedia
      ];
    };
  };

  # Configuration option for selecting theme
  cfg = config.services.displayManager.sddm.theme-config or "astronaut-hacker";
  selectedTheme = themes.${cfg} or themes.astronaut-hacker;

in {
  # Option to select theme
  options.services.displayManager.sddm.theme-config = lib.mkOption {
    type = lib.types.enum (builtins.attrNames themes);
    default = "astronaut-hacker";
    description = "SDDM theme to use";
    example = "astronaut-hacker";
  };

  config = {
    # Install theme package if needed
    environment.systemPackages = lib.optionals (selectedTheme.package != null) [
      selectedTheme.package
    ] ++ selectedTheme.extraPackages ++ [
      # Icon themes for comprehensive coverage
      pkgs.adwaita-icon-theme      # GNOME default icons
      pkgs.hicolor-icon-theme      # Fallback icon theme (required)
      pkgs.papirus-icon-theme      # Modern colorful icons (best app coverage)
      pkgs.tela-icon-theme         # Flat modern icons
      pkgs.numix-icon-theme        # Popular flat icons
      pkgs.kdePackages.breeze-icons  # KDE icons for compatibility
      pkgs.libsForQt5.breeze-icons # Qt5 breeze icons
      pkgs.gnome-themes-extra      # Additional GNOME icons

      # GTK themes for modern dark aesthetic
      pkgs.arc-theme              # Modern flat theme
      pkgs.numix-gtk-theme        # Beautiful flat dark theme (primary)
      pkgs.nordic                 # Dark Nordic theme
    ];

    # Configure SDDM with appropriate Qt version per theme
    services = {
      # Enable upower for battery management
      upower.enable = lib.mkDefault true;

      displayManager.sddm = {
      enable = true;

      # Use Qt5 SDDM for astronaut themes
      package = lib.mkForce (if (cfg == "astronaut-default" || cfg == "astronaut-hacker")
                then pkgs.libsForQt5.sddm  # Qt5 SDDM for astronaut themes
                else pkgs.libsForQt5.sddm); # Default to Qt5 SDDM

      wayland.enable = true;  # Enable Wayland support for SDDM
      theme = selectedTheme.name;

      # Settings based on working configuration
      settings = {
        General = {
          # Don't force display server - let session choose
        };
        Theme = {
          Current = selectedTheme.name;
          ThemeDir = "/run/current-system/sw/share/sddm/themes";
          CursorTheme = "breeze_cursors";
          Font = "JetBrains Mono,12,-1,0,50,0,0,0,0,0";
        };
        # Hide usernames for security - force override
        Users = {
          HideUsers = "jason,*";  # Explicitly hide your username and all others
          HideShells = "/bin/false,/usr/bin/nologin,/run/current-system/sw/bin/nologin";
          RememberLastUser = false;
          RememberLastSession = false;
          MaximumUid = 65000;
          MinimumUid = 1000;
        };
      };
    };
    };

    # Theme configuration files
    environment.etc = lib.mkMerge [
      # GTK theme configuration for consistent dark theme
      {
        "gtk-3.0/settings.ini".text = ''
          [Settings]
          gtk-theme-name=Numix-DarkBlue
          gtk-icon-theme-name=Tela-dark
          gtk-cursor-theme-name=breeze_cursors
          gtk-cursor-theme-size=24
          gtk-font-name=JetBrains Mono 11
          gtk-application-prefer-dark-theme=true
          gtk-button-images=true
          gtk-menu-images=true
          gtk-enable-event-sounds=false
          gtk-enable-input-feedback-sounds=false
          gtk-xft-antialias=1
          gtk-xft-hinting=1
          gtk-xft-hintstyle=hintslight
          gtk-xft-rgba=rgb
        '';

        "gtk-4.0/settings.ini".text = ''
          [Settings]
          gtk-theme-name=Numix-DarkBlue
          gtk-icon-theme-name=Tela-dark
          gtk-cursor-theme-name=breeze_cursors
          gtk-cursor-theme-size=24
          gtk-font-name=JetBrains Mono 11
          gtk-application-prefer-dark-theme=true
          gtk-enable-event-sounds=false
          gtk-enable-input-feedback-sounds=false
          gtk-xft-antialias=1
          gtk-xft-hinting=1
          gtk-xft-hintstyle=hintslight
          gtk-xft-rgba=rgb
        '';
      }
      # Custom theme configuration for astronaut themes
      (lib.mkIf (cfg == "astronaut-default" || cfg == "astronaut-hacker") {
        "sddm.conf.d/theme.conf".text = ''
          [Theme]
          Current=sddm-astronaut-theme
          ThemeDir=/run/current-system/sw/share/sddm/themes
          CursorTheme=breeze_cursors
          Font=JetBrains Mono,12,-1,0,50,0,0,0,0,0

          [Users]
          HideUsers=jason,*
          HideShells=/bin/false,/usr/bin/nologin,/run/current-system/sw/bin/nologin
          RememberLastUser=false
          RememberLastSession=false
          MaximumUid=65000
          MinimumUid=1000

        '';
      })
    ];

    # Ensure GTK themes are applied for all users
    programs.dconf.enable = true;

    # Create user GTK configuration directory and symlinks
    systemd.user.services.gtk-config = {
      description = "Setup GTK configuration";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p $HOME/.config/gtk-3.0 $HOME/.config/gtk-4.0 && ln -sf /etc/gtk-3.0/settings.ini $HOME/.config/gtk-3.0/settings.ini && ln -sf /etc/gtk-4.0/settings.ini $HOME/.config/gtk-4.0/settings.ini'";
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
  };
}