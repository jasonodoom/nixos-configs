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
    # Working astronaut theme with Qt5 compatibility
    astronaut-hacker = {
      name = "sddm-astronaut-theme";
      # Manual theme installation (like working commit eb5f242)
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
      # Qt5 packages only (to avoid Qt dependency conflicts)
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

    # MacSonoma-kde theme (complete macOS Sonoma desktop theming)
    macsonoma = {
      name = "MacSonoma-6.0";
      package = pkgs.stdenv.mkDerivation {
        name = "macsonoma-kde-theme";
        src = pkgs.fetchFromGitHub {
          owner = "vinceliuice";
          repo = "MacSonoma-kde";
          rev = "main";
          sha256 = "sha256-0mecdt/uMtpoQRuJsMaCmB7LDw7BQs5Y4CQCsy0tieg=";
        };


        installPhase = ''
          mkdir -p $out/share/themes
          mkdir -p $out/share/Kvantum
          mkdir -p $out/share/aurorae/themes
          mkdir -p $out/share/color-schemes
          mkdir -p $out/share/plasma/desktoptheme
          mkdir -p $out/share/plasma/look-and-feel
          mkdir -p $out/share/wallpapers
          mkdir -p $out/share/sddm/themes

          # Install Kvantum theme
          cp -r Kvantum/MacSonoma $out/share/Kvantum/

          # Install Aurorae window decorations
          cp -r aurorae/* $out/share/aurorae/themes/

          # Install color schemes
          cp -r color-schemes/* $out/share/color-schemes/

          # Install plasma themes
          cp -r plasma/desktoptheme/* $out/share/plasma/desktoptheme/
          cp -r plasma/look-and-feel/* $out/share/plasma/look-and-feel/

          # Install wallpapers
          cp -r wallpapers/* $out/share/wallpapers/

          # Install SDDM theme if it exists
          if [ -d "sddm" ]; then
            cp -r sddm/* $out/share/sddm/themes/
          fi

          # Copy custom background image
          cp ${./hyprland/wallpapers/sddm-background.png} $out/share/sddm/themes/MacSonoma-6.0/Background.jpg

          # Create NixOS snowflake icons in multiple formats and sizes
          mkdir -p $out/share/icons/MacSonoma/apps/scalable
          mkdir -p $out/share/icons/MacSonoma/apps/48
          mkdir -p $out/share/icons/MacSonoma/apps/64
          mkdir -p $out/share/pixmaps

          # Create SVG NixOS snowflake icon
          cat > $out/share/icons/MacSonoma/apps/scalable/nix-snowflake.svg << 'EOF'
          <svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <linearGradient id="nixGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:#4A90E2;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#357ABD;stop-opacity:1" />
              </linearGradient>
            </defs>
            <circle cx="32" cy="32" r="30" fill="url(#nixGradient)" stroke="#2C5282" stroke-width="2"/>
            <text x="32" y="42" text-anchor="middle" font-family="SF Pro Display, -apple-system, sans-serif"
                  font-size="24" font-weight="300" fill="white">❄️</text>
          </svg>
          EOF

          # Copy to other required locations
          cp $out/share/icons/MacSonoma/apps/scalable/nix-snowflake.svg $out/share/pixmaps/
          cp $out/share/icons/MacSonoma/apps/scalable/nix-snowflake.svg $out/nixos-logo.svg

          # Replace Apple logos and references throughout the theme
          find $out -type f \( -name "*.svg" -o -name "*.qml" -o -name "*.js" -o -name "*.desktop" -o -name "*.conf" \) -exec sed -i \
            -e 's|apple\.svg|nix-snowflake.svg|g' \
            -e 's|apple-logo|nix-snowflake|g' \
            -e 's|Apple|NixOS|g' \
            -e 's|macOS|NixOS|g' \
            -e 's|🍎|❄️|g' \
            -e 's|Finder|Dolphin|g' \
            -e 's|com\.apple\.|org.nixos.|g' \
            {} \;

          # Create a custom launcher icon configuration
          mkdir -p $out/share/applications
          cat > $out/share/applications/nix-launcher.desktop << 'EOF'
          [Desktop Entry]
          Type=Application
          Name=NixOS
          Comment=NixOS System
          Icon=nix-snowflake
          Exec=systemsettings
          Categories=System;Settings;
          EOF
        '';
      };

      # Required packages for MacSonoma theme
      extraPackages = [
        # Kvantum engine for theme styling
        pkgs.libsForQt5.qtstyleplugin-kvantum
        pkgs.qt6Packages.qtstyleplugin-kvantum

        # GTK theme support
        pkgs.gtk3
        pkgs.gtk4

        # Icon and cursor themes
        pkgs.kdePackages.breeze-icons
        pkgs.kdePackages.breeze

        # Full KDE Plasma desktop environment for QML modules
        pkgs.kdePackages.plasma-desktop
        pkgs.kdePackages.plasma-workspace
        pkgs.kdePackages.plasma5support
        pkgs.kdePackages.kirigami
        pkgs.kdePackages.breeze
        pkgs.kdePackages.kconfig
        pkgs.kdePackages.kconfigwidgets
        pkgs.kdePackages.kservice
        pkgs.kdePackages.kdeclarative
        pkgs.kdePackages.kquickcharts
        pkgs.kdePackages.libplasma
        pkgs.kdePackages.plasma-activities
        pkgs.kdePackages.kglobalaccel
        # Qt6 plasma framework is provided by libplasma above

        # Qt modules for SDDM theme compatibility
        pkgs.qt6Packages.qt5compat
        pkgs.qt6Packages.qtdeclarative
        pkgs.qt6Packages.qtsvg
        pkgs.qt6Packages.qtquick3d
        pkgs.qt6Packages.qtmultimedia
        pkgs.qt6Packages.qtvirtualkeyboard

        # Hunspell dictionary for virtual keyboard
        pkgs.hunspell
        pkgs.hunspellDicts.en_US
      ];
    };
  };

  # Configuration option for selecting theme
  cfg = config.services.displayManager.sddm.theme-config or "macsonoma";
  selectedTheme = themes.${cfg} or themes.macsonoma;

in {
  # Option to select theme
  options.services.displayManager.sddm.theme-config = lib.mkOption {
    type = lib.types.enum (builtins.attrNames themes);
    default = "macsonoma";
    description = "SDDM theme to use";
    example = "astronaut-hacker";
  };

  config = {
    # Install theme package if needed
    environment.systemPackages = lib.optionals (selectedTheme.package != null) [
      selectedTheme.package
    ] ++ selectedTheme.extraPackages;

    # Configure SDDM with appropriate Qt version per theme
    services = {
      # KDE Plasma 6 desktop is now configured in kde-config.nix
      upower.enable = lib.mkForce true;  # Resolve conflict between Hyprland and Plasma6

      displayManager.sddm = {
      enable = true;

      # Use Qt6 SDDM for MacSonoma theme (designed for Plasma 6), Qt5 for astronaut themes
      package = lib.mkForce (if (cfg == "astronaut-default" || cfg == "astronaut-hacker")
                then pkgs.libsForQt5.sddm  # Qt5 SDDM for astronaut themes
                else if (cfg == "macsonoma")
                then pkgs.kdePackages.sddm  # Qt6 SDDM for MacSonoma theme
                else null); # Use default for other themes

      wayland.enable = false;
      theme = selectedTheme.name;

      # Settings based on working configuration
      settings = {
        General = {
          DisplayServer = "x11";
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

    # Custom theme configuration for astronaut themes
    environment.etc = lib.mkIf (cfg == "astronaut-default" || cfg == "astronaut-hacker") {
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