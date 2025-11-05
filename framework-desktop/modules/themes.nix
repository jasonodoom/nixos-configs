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
  cfg = config.services.displayManager.sddm.theme-config or "astronaut-hacker";
  selectedTheme = themes.${cfg} or themes.astronaut-hacker;

in {
  # Option to select theme
  options.services.displayManager.sddm.theme-config = lib.mkOption {
    type = lib.types.enum (builtins.attrNames themes);
    default = "astronaut-hacker";
    description = "SDDM theme to use";
    example = "astronaut-default";
  };

  config = {
    # Install theme package if needed
    environment.systemPackages = lib.optionals (selectedTheme.package != null) [
      selectedTheme.package
    ];

    # Configure SDDM with selected theme
    services.displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm; # Qt6 SDDM version for Qt6 themes
      wayland.enable = false; # Use X11 mode for better theme compatibility
      theme = selectedTheme.name;
      extraPackages = selectedTheme.extraPackages;

      # Security settings - require manual username entry
      settings = {
        General = {
          DisplayServer = "x11";
        };
        Theme = {
          Current = selectedTheme.name;
        };
        Users = {
          HideUsers = "";
          HideShells = "/bin/false,/usr/bin/nologin";
          RememberLastUser = false;
        };
      };
    };
  };
}