# Hyprland configuration
{ config, pkgs, lib, inputs, ... }:

{
  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true;  # Universal Wayland Session Manager (recommended)
    xwayland.enable = true;  # Enable XWayland for X11 app compatibility
  };

  # SDDM theme configuration is now handled by themes.nix
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
    bind = $mod, R, exec, rofi -show drun -config /etc/xdg/rofi/config.rasi
    bind = $mod, D, exec, rofi -show run -config /etc/xdg/rofi/config.rasi
    bind = $mod SHIFT, R, exec, rofi -show window -config /etc/xdg/rofi/config.rasi
    bind = $mod, P, pseudo
    bind = $mod, J, togglesplit

    # Additional app launcher shortcut (Space for quick access)
    bind = $mod, space, exec, rofi -show drun -config /etc/xdg/rofi/config.rasi

    # Waybar controls
    bind = $mod SHIFT, B, exec, killall waybar && waybar -c /etc/xdg/waybar/config -s /etc/xdg/waybar/style.css &
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

    # Screen lock binding
    bind = $mod, L, exec, swaylock -f -c 1a1b26 --inside-color 7aa2f7aa --ring-color bb9af7aa --key-hl-color 9ece6aaa --line-color 00000000 --separator-color 00000000 --text-color c0caf5 --clock --indicator

    # Power management shortcuts
    bind = $mod SHIFT, L, exec, loginctl lock-session
    bind = $mod SHIFT, Q, exec, hyprctl dispatch exit
    bind = $mod SHIFT, S, exec, systemctl suspend
    bind = $mod, Escape, exec, wlogout --layer-shell
    bind = $mod SHIFT, P, exec, wlogout --layer-shell

    # Direct power shortcuts (with confirmation)
    bind = $mod CTRL SHIFT, R, exec, systemctl reboot
    bind = $mod CTRL SHIFT, S, exec, systemctl poweroff

    # Mouse binds
    bindm = $mod, mouse:272, movewindow
    bindm = $mod, mouse:273, resizewindow

    # Wallpaper - use swaybg as fallback to avoid startup issues
    exec-once = swaybg -c "#1e1e2e"

    # Kill any duplicate applets that might autostart
    exec-once = pkill nm-applet || true
    exec-once = pkill blueman-applet || true

    # Autostart applications with proper timing and error handling
    exec-once = sleep 1 && pkill waybar || true
    exec-once = sleep 2 && waybar --config /etc/xdg/waybar/config --style /etc/xdg/waybar/style.css --log-level info
    # Fallback waybar startup if first attempt fails
    exec-once = sleep 8 && pgrep waybar || waybar --config /etc/xdg/waybar/config --style /etc/xdg/waybar/style.css
    # Removed nm-applet and blueman-applet - waybar handles these with styled modules
  '';

  # Wlogout configuration (beautiful graphical power menu)
  environment.etc."xdg/wlogout/layout".text = ''
    {
        "label" : "lock",
        "action" : "swaylock -f -c 1a1b26 --inside-color 7aa2f7aa --ring-color bb9af7aa --key-hl-color 9ece6aaa --line-color 00000000 --separator-color 00000000 --text-color c0caf5 --clock --indicator",
        "text" : "Lock",
        "keybind" : "l"
    }
    {
        "label" : "hibernate",
        "action" : "systemctl hibernate",
        "text" : "Hibernate",
        "keybind" : "h"
    }
    {
        "label" : "logout",
        "action" : "hyprctl dispatch exit",
        "text" : "Logout",
        "keybind" : "e"
    }
    {
        "label" : "shutdown",
        "action" : "systemctl poweroff",
        "text" : "Shutdown",
        "keybind" : "s"
    }
    {
        "label" : "suspend",
        "action" : "systemctl suspend",
        "text" : "Suspend",
        "keybind" : "u"
    }
    {
        "label" : "reboot",
        "action" : "systemctl reboot",
        "text" : "Reboot",
        "keybind" : "r"
    }
  '';

  # Wlogout styling (Tokyo Night theme)
  environment.etc."xdg/wlogout/style.css".text = ''
    * {
      background-image: none;
      box-shadow: none;
    }

    window {
      background-color: rgba(26, 27, 38, 0.9);
    }

    button {
      color: #c0caf5;
      background-color: rgba(36, 40, 59, 0.8);
      border-style: solid;
      border-width: 2px;
      background-repeat: no-repeat;
      background-position: center;
      background-size: 25%;
      border-radius: 10px;
      margin: 5px;
      transition: all 0.3s ease;
    }

    button:focus, button:active, button:hover {
      background-color: rgba(122, 162, 247, 0.2);
      outline-style: none;
      border-color: #7aa2f7;
      color: #7aa2f7;
      box-shadow: 0 0 20px rgba(122, 162, 247, 0.3);
    }

    #lock {
      background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
      border-color: #f7768e;
    }

    #logout {
      background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
      border-color: #e0af68;
    }

    #suspend {
      background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
      border-color: #9ece6a;
    }

    #hibernate {
      background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png"));
      border-color: #7dcfff;
    }

    #shutdown {
      background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
      border-color: #bb9af7;
    }

    #reboot {
      background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
      border-color: #7aa2f7;
    }

    #lock:hover {
      border-color: #f7768e;
      background-color: rgba(247, 118, 142, 0.1);
    }

    #logout:hover {
      border-color: #e0af68;
      background-color: rgba(224, 175, 104, 0.1);
    }

    #suspend:hover {
      border-color: #9ece6a;
      background-color: rgba(158, 206, 106, 0.1);
    }

    #hibernate:hover {
      border-color: #7dcfff;
      background-color: rgba(125, 207, 255, 0.1);
    }

    #shutdown:hover {
      border-color: #bb9af7;
      background-color: rgba(187, 154, 247, 0.1);
    }

    #reboot:hover {
      border-color: #7aa2f7;
      background-color: rgba(122, 162, 247, 0.1);
    }
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
    swaylock
    swaybg
    wlogout

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

    # SDDM theme packages are now managed by themes.nix

    # Qt5 compatibility for SDDM theme (keeping for compatibility)
    qt5.qtgraphicaleffects
    qt5.qtquickcontrols2
    qt5.qtsvg
  ];

  # Enable required services
  services = {
    dbus.enable = true;
    gnome.gnome-keyring.enable = true;
    upower.enable = true;
  };

  # Disable NetworkManager applet autostart to prevent duplicate network icons
  systemd.user.services.nm-applet = {
    enable = false;
  };

  # Fix PAM configuration for gnome-keyring to resolve challenge-response errors
  security.pam.services = {
    login.enableGnomeKeyring = true;
    sddm.enableGnomeKeyring = true;
    sddm-greeter.enableGnomeKeyring = true;
    passwd.enableGnomeKeyring = true;
  };

  # Session variables
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    HYPRLAND_NO_RT = "1";  # Disable Hyprland update notifications
  };

}