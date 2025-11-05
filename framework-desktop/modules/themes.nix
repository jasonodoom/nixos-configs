# SDDM Theme Configuration Module
{ config, pkgs, lib, ... }:

let
  # Available theme configurations
  themes = {
    # Post-apocalyptic hacker variant of astronaut theme
    astronaut-hacker = {
      name = "sddm-astronaut-theme";
      package = pkgs.sddm-astronaut.override {
        embeddedTheme = "post-apocalyptic_hacker";
        themeConfig = {
          # Add any custom theme configuration here if needed
        };
      };
      extraPackages = [
        pkgs.kdePackages.qtmultimedia
        pkgs.kdePackages.qtsvg
      ];
    };

    # Default astronaut theme
    astronaut-default = {
      name = "sddm-astronaut-theme";
      package = pkgs.sddm-astronaut.override {
        embeddedTheme = "astronaut";
        themeConfig = {
          # Add any custom theme configuration here if needed
        };
      };
      extraPackages = [
        pkgs.kdePackages.qtmultimedia
        pkgs.kdePackages.qtsvg
      ];
    };

    # Maya theme (already included in SDDM)
    maya = {
      name = "maya";
      package = null; # Built-in theme
      extraPackages = [];
    };

    # Maldives theme (already included in SDDM)
    maldives = {
      name = "maldives";
      package = null; # Built-in theme
      extraPackages = [];
    };
  };

  # Configuration option for selecting theme
  cfg = config.services.displayManager.sddm.theme-config or "astronaut-default";
  selectedTheme = themes.${cfg} or themes.astronaut-default;

in {
  # Option to select theme
  options.services.displayManager.sddm.theme-config = lib.mkOption {
    type = lib.types.enum (builtins.attrNames themes);
    default = "astronaut-default";
    description = "SDDM theme to use";
    example = "astronaut-default";
  };

  config = {
    # Install theme package and Qt6 dependencies for astronaut themes
    environment.systemPackages = lib.optionals (selectedTheme.package != null) [
      selectedTheme.package
    ] ++ lib.optionals (cfg == "astronaut-default" || cfg == "astronaut-hacker") [
      # Additional Qt6 packages needed for astronaut theme based on GitHub issues
      pkgs.kdePackages.qtmultimedia
      pkgs.kdePackages.qtsvg
    ];

    # Configure SDDM with conditional settings based on theme
    services.displayManager.sddm = {
      enable = true;

      # Use Qt6 only for themes that specifically need it
      package = if (cfg == "astronaut-default" || cfg == "astronaut-hacker")
                then pkgs.kdePackages.sddm
                else null; # Use default Qt5 SDDM for other themes

      wayland.enable = false;
      theme = selectedTheme.name;

      # Only add extraPackages for Qt6 themes
      extraPackages = if (cfg == "astronaut-default" || cfg == "astronaut-hacker")
                      then selectedTheme.extraPackages
                      else [];

      # Settings optimized for astronaut theme vs others
      settings = {
        General = {
          DisplayServer = "x11";
        };
        Theme = {
          Current = selectedTheme.name;
        };
        Users = {
          # Hide all users for security - no username shown
          HideUsers = "*";
          HideShells = "/bin/false,/usr/bin/nologin";
          RememberLastUser = false;
        };
      };
    };
  };
}