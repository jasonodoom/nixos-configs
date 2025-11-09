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
        # Disable automatic login to force manual entry
        autoSuspend = false;
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

    # AccountsService for user management (GNOME user avatar)
    accounts-daemon.enable = lib.mkIf useGnomeAsDefault true;

    # D-Bus service (shared across desktop environments)
    dbus.enable = lib.mkDefault true;
  };

  # Hide system users from appearing in user lists
  environment.etc = lib.mkIf useGnomeAsDefault {
    "accountsservice/users/gdm" = {
      text = ''
        [User]
        SystemAccount=true
        Language=
      '';
      mode = "0644";
    };
  };

  # Configure dconf for both GDM and user settings
  programs.dconf = lib.mkIf useGnomeAsDefault {
    enable = true;
    # GDM login screen settings
    profiles.gdm.databases = [{
      settings = {
        "org/gnome/login-screen" = {
          enable-fingerprint-authentication = false;
          enable-smartcard-authentication = false;
          enable-password-authentication = true;
          disable-user-list = true;
        };
        "org/gnome/desktop/screensaver" = {
          user-switch-enabled = false;
        };
        "org/gnome/desktop/interface" = {
          clock-show-seconds = false;
          clock-format = "12h";
        };
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-timeout = lib.gvariant.mkInt32 900;
          sleep-inactive-ac-type = "nothing";
          idle-dim = true;
          idle-brightness = lib.gvariant.mkInt32 30;
        };
        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 60;
        };
        "org/gnome/desktop/screensaver" = {
          idle-activation-enabled = true;
          lock-enabled = true;
          lock-delay = lib.gvariant.mkUint32 0;
        };
      };
    }];
    # User default settings
    profiles.user.databases = [{
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

        # Interface and cursor configuration
        "org/gnome/desktop/interface" = {
          gtk-theme = "Numix-DarkBlue";
          icon-theme = "Tela-dark";
          cursor-theme = "breeze_cursors";
          cursor-size = lib.gvariant.mkInt32 24;
          font-name = "JetBrains Mono 11";
        };

        # Custom keybindings
        "org/gnome/settings-daemon/plugins/media-keys" = {
          custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          ];
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "<Super>r";
          command = "rofi -show drun";
          name = "Launch Rofi";
        };


        # Power management settings (desktop - don't suspend)
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-timeout = lib.gvariant.mkInt32 900;
          sleep-inactive-ac-type = "nothing";
          idle-dim = true;
          idle-brightness = lib.gvariant.mkInt32 30;
        };
        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 60;
        };
        "org/gnome/desktop/screensaver" = {
          idle-activation-enabled = true;
          lock-enabled = true;
          lock-delay = lib.gvariant.mkUint32 0;
        };
      };
    }];
  };

  # Ensure proper display manager startup dependencies to prevent TTY hanging
  systemd.services.display-manager = lib.mkIf useGnomeAsDefault {
    wants = [ "systemd-user-sessions.service" "plymouth-quit.service" ];
    after = [ "systemd-user-sessions.service" "plymouth-quit.service" "systemd-logind.service" "dconf-update.service" ];
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
    gnomeExtensions.clipboard-indicator

    # GNOME apps and utilities
    gnome-tweaks
    dconf-editor
    gnome-extension-manager
    rofi  # Application launcher for Super+R keybinding

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

  # dconf settings already configured above in main programs.dconf block

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

  # Power management now configured via dconf above



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