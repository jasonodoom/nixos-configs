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

          # Create NixOS-branded logo file
          cat > $out/nixos-logo.svg << 'EOF'
          <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <text x="12" y="16" text-anchor="middle" font-family="Arial" font-size="20">❄️</text>
          </svg>
          EOF

          # Replace Apple logos in theme files with NixOS snowflake
          find $out -type f \( -name "*.svg" -o -name "*.qml" -o -name "*.js" \) -exec sed -i \
            -e 's|apple\.svg|nixos-logo.svg|g' \
            -e 's|Apple|NixOS|g' \
            -e 's|🍎|❄️|g' \
            {} \;
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

        # Icon and cursor themes (WhiteSur recommended)
        pkgs.libsForQt5.breeze-icons
        pkgs.libsForQt5.breeze-qt5
        pkgs.kdePackages.breeze-icons

        # Additional KDE theming support
        pkgs.libsForQt5.plasma-framework
        pkgs.kdePackages.plasma5support
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

    # Configure SDDM with working Qt5 setup
    services.displayManager.sddm = {
      enable = true;

      # Use Qt6 SDDM for MacSonoma, Qt5 for astronaut themes
      package = if (cfg == "astronaut-default" || cfg == "astronaut-hacker")
                then pkgs.libsForQt5.sddm  # Qt5 SDDM for astronaut themes
                else if (cfg == "macsonoma")
                then pkgs.kdePackages.sddm  # Qt6 SDDM for MacSonoma
                else null; # Use default for other themes

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