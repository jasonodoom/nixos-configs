# Hyprland configuration
{ config, pkgs, lib, inputs, ... }:

{
  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true;  # Universal Wayland Session Manager (recommended)
    xwayland.enable = true;  # Enable XWayland for X11 app compatibility
  };

  # Display manager for Hyprland
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;  # Use X11 mode for better theme compatibility
    theme = "sddm-astronaut-theme";  # Use astronaut theme
    settings = {
      Theme = {
        Current = "sddm-astronaut-theme";
        CursorTheme = "breeze_cursors";
        Font = "JetBrains Mono,12,-1,0,50,0,0,0,0,0";
      };
      General = {
        DisplayServer = "x11";
      };
    };
  };

  services.displayManager.defaultSession = "hyprland-uwsm";



  # Hyprland system configuration
  environment.etc."hypr/hyprland.conf".text = ''
    # Monitor configuration - auto-detect displays
    # Let Hyprland automatically detect and configure displays
    monitor=,preferred,auto,1

    # Disable update news dialog and logo
    misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true
    }

    # Input configuration
    input {
        kb_layout = us
        follow_mouse = 1
        sensitivity = 0
    }

    # General settings
    general {
        gaps_in = 5
        gaps_out = 20
        border_size = 2
        col.active_border = rgba(bb9af7ee) rgba(7aa2f7ee) 45deg
        col.inactive_border = rgba(32344aaa)
        layout = dwindle
    }

    # Decorations
    decoration {
        rounding = 10
        blur {
            enabled = true
            size = 3
            passes = 1
            new_optimizations = true
            xray = true
        }
        drop_shadow = true
        shadow_range = 4
        shadow_render_power = 3
        col.shadow = rgba(1a1a1aee)
        col.shadow_inactive = rgba(1a1a1a77)
    }

    # Animations
    animations {
        enabled = true
        bezier = myBezier, 0.05, 0.9, 0.1, 1.05
        animation = windows, 1, 7, myBezier
        animation = windowsOut, 1, 7, default, popin 80%
        animation = border, 1, 10, default
        animation = borderangle, 1, 8, default
        animation = fade, 1, 7, default
        animation = workspaces, 1, 6, default
    }

    # Dwindle layout
    dwindle {
        pseudotile = true
        preserve_split = true
    }

    # Window rules
    windowrulev2 = float,class:^(pavucontrol)$
    windowrulev2 = float,class:^(blueman-manager)$
    windowrulev2 = float,class:^(nm-applet)$
    windowrulev2 = float,class:^(firefox),title:^(Picture-in-Picture)$

    # Keybindings
    $mod = SUPER

    # Program shortcuts
    bind = $mod, Return, exec, kitty
    bind = $mod, T, exec, kitty
    bind = $mod, Q, killactive
    bind = $mod, M, exit
    bind = $mod, V, togglefloating
    bind = $mod, R, exec, rofi -show drun
    bind = $mod, P, pseudo
    bind = $mod, J, togglesplit

    # Waybar controls
    bind = $mod SHIFT, B, exec, killall waybar && waybar &
    bind = $mod CTRL, B, exec, killall waybar

    # Hyprland reload
    bind = $mod CTRL, R, exec, hyprctl reload

    # Move focus
    bind = $mod, left, movefocus, l
    bind = $mod, right, movefocus, r
    bind = $mod, up, movefocus, u
    bind = $mod, down, movefocus, d

    # Switch workspaces
    bind = $mod, 1, workspace, 1
    bind = $mod, 2, workspace, 2
    bind = $mod, 3, workspace, 3
    bind = $mod, 4, workspace, 4
    bind = $mod, 5, workspace, 5
    bind = $mod, 6, workspace, 6
    bind = $mod, 7, workspace, 7
    bind = $mod, 8, workspace, 8
    bind = $mod, 9, workspace, 9
    bind = $mod, 0, workspace, 10

    # Move windows to workspaces
    bind = $mod SHIFT, 1, movetoworkspace, 1
    bind = $mod SHIFT, 2, movetoworkspace, 2
    bind = $mod SHIFT, 3, movetoworkspace, 3
    bind = $mod SHIFT, 4, movetoworkspace, 4
    bind = $mod SHIFT, 5, movetoworkspace, 5
    bind = $mod SHIFT, 6, movetoworkspace, 6
    bind = $mod SHIFT, 7, movetoworkspace, 7
    bind = $mod SHIFT, 8, movetoworkspace, 8
    bind = $mod SHIFT, 9, movetoworkspace, 9
    bind = $mod SHIFT, 0, movetoworkspace, 10

    # Scroll through workspaces
    bind = $mod, mouse_down, workspace, e+1
    bind = $mod, mouse_up, workspace, e-1

    # Screenshots
    bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
    bind = $mod, Print, exec, grim - | wl-copy

    # Mouse binds
    bindm = $mod, mouse:272, movewindow
    bindm = $mod, mouse:273, resizewindow

    # Autostart applications
    exec-once = sleep 2 && /run/current-system/sw/bin/waybar
    exec-once = /run/current-system/sw/bin/nm-applet --indicator
    exec-once = /run/current-system/sw/bin/blueman-applet
  '';

  # Kitty terminal configuration
  environment.etc."xdg/kitty/kitty.conf".text = ''
    font_family Fira Code
    font_size 12
    background_opacity 0.9
    window_padding_width 8

    # Dark theme colors (Tokyo Night)
    foreground #c0caf5
    background #1a1b26
    selection_foreground #c0caf5
    selection_background #33467c

    # Cursor colors
    cursor #c0caf5
    cursor_text_color #1a1b26

    # URL underline color when hovering with mouse
    url_color #73daca

    # Kitty window border colors
    active_border_color #7aa2f7
    inactive_border_color #292e42
    bell_border_color #e0af68

    # OS Window titlebar colors
    wayland_titlebar_color system
    macos_titlebar_color system

    # Tab bar colors
    active_tab_foreground #1f2335
    active_tab_background #7aa2f7
    inactive_tab_foreground #545c7e
    inactive_tab_background #292e42
    tab_bar_background #1d202f

    # Colors for marks (marked text in the terminal)
    mark1_foreground #1a1b26
    mark1_background #73daca
    mark2_foreground #1a1b26
    mark2_background #7dcfff
    mark3_foreground #1a1b26
    mark3_background #7aa2f7

    # The 16 terminal colors

    # black
    color0 #15161e
    color8 #414868

    # red
    color1 #f7768e
    color9 #f7768e

    # green
    color2 #9ece6a
    color10 #9ece6a

    # yellow
    color3 #e0af68
    color11 #e0af68

    # blue
    color4 #7aa2f7
    color12 #7aa2f7

    # magenta
    color5 #bb9af7
    color13 #bb9af7

    # cyan
    color6 #7dcfff
    color14 #7dcfff

    # white
    color7 #a9b1d6
    color15 #c0caf5
  '';

  # Required for Hyprland
  security.polkit.enable = true;

  # XDG portal configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland  # Required for Hyprland
      xdg-desktop-portal-gtk
    ];
  };


  # Enable X11 support for SDDM
  services.xserver.enable = true;

  # Essential Hyprland packages
  environment.systemPackages = with pkgs; [
    # Wayland utilities
    wl-clipboard
    wlr-randr
    waybar
    wofi
    grim
    slurp
    swayidle
    swaylock-effects

    libnotify
    dunst
    pamixer
    xdg-user-dirs
    libcanberra
    wirelesstools

    # File manager
    xfce.thunar

    # Terminal
    kitty

    # Application launcher
    rofi-wayland

    # Screenshot tools
    flameshot

    # Audio control
    pamixer

    # Network applet
    networkmanagerapplet

    # Bluetooth applet
    blueman

    # SDDM themes and icons
    libsForQt5.breeze-qt5
    libsForQt5.breeze-icons
    libsForQt5.breeze-gtk
    kdePackages.breeze
    kdePackages.breeze-icons

    # SDDM theme packages
    libsForQt5.sddm-kcm  # SDDM configuration module

    # Qt6 dependencies for SDDM astronaut theme
    kdePackages.qtsvg
    kdePackages.qtvirtualkeyboard
    kdePackages.qtmultimedia

    # Qt5 compatibility for SDDM theme
    qt5.qtgraphicaleffects
    qt5.qtquickcontrols2
    qt5.qtsvg

    # SDDM Astronaut theme
    (stdenv.mkDerivation {
      name = "sddm-astronaut-theme";
      src = fetchFromGitHub {
        owner = "Keyitdev";
        repo = "sddm-astronaut-theme";
        rev = "468a100460d5feaa701c2215c737b55789cba0fc";
        sha256 = "sha256-L+5xoyjX3/nqjWtMRlHR/QfAXtnICyGzxesSZexZQMA=";
      };
      installPhase = ''
        mkdir -p $out/share/sddm/themes/sddm-astronaut-theme
        cp -R * $out/share/sddm/themes/sddm-astronaut-theme/
      '';
    })
  ];

  # Enable required services
  services = {
    dbus.enable = true;
    gnome.gnome-keyring.enable = true;
    upower.enable = true;
  };

  # Session variables
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    HYPRLAND_NO_RT = "1";  # Disable Hyprland update notifications
  };

}