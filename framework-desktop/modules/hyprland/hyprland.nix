# Hyprland configuration
{ config, pkgs, lib, inputs, pkgs-unstable, ... }:

with lib; let
  # Hyprland plugins from nixpkgs-unstable
  hypr-plugin-dir = pkgs.symlinkJoin {
    name = "hyprland-plugins";
    paths = with pkgs-unstable.hyprlandPlugins; [
      hy3
      hyprexpo
      hyprfocus
      hyprbars
      # hyprspace  # disabled: broken with hyprland 0.53+ (nixpkgs#443989)
    ];
  };
in
{
  imports = [
    ./binds.nix
  ];
  # Enable Hyprland from unstable for latest version and plugin compatibility
  # Only enable if GNOME is not the default desktop
  programs.hyprland = {
    enable = lib.mkDefault (!config.services.desktopManager.gnome.enable);
    package = pkgs-unstable.hyprland;
    withUWSM = true;  # Universal Wayland Session Manager (recommended)
    xwayland.enable = true;  # Enable XWayland for X11 app compatibility
  };


  # Force Hyprland to use system config and set up XDG directories
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    HYPRLAND_NO_RT = "1";  # Disable Hyprland update notifications

    # XDG directories for proper config discovery (use mkDefault to avoid conflicts)
    XDG_CONFIG_DIRS = lib.mkDefault "/etc/xdg";
    XDG_DATA_DIRS = lib.mkDefault "/run/current-system/sw/share";

    # Ensure rofi finds its config
    XDG_CONFIG_HOME = lib.mkDefault "$HOME/.config";

    # Plugin directory for Hyprland plugins
    HYPR_PLUGIN_DIR = "${hypr-plugin-dir}";
  };

  # Create a wrapper that forces the config path - only when GNOME is not enabled
  systemd.user.services.hyprland-config = lib.mkIf (!config.services.desktopManager.gnome.enable) {
    description = "Hyprland config symlink";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p $HOME/.config/hypr && ln -sf /etc/hypr/hyprland.conf $HOME/.config/hypr/hyprland.conf'";
    };
  };

  # SDDM theme configuration is now handled by themes.nix
  # Set default session based on UWSM configuration - only when GNOME is not enabled
  services.displayManager.defaultSession = lib.mkIf (!config.services.desktopManager.gnome.enable)
    (if config.programs.hyprland.withUWSM then "hyprland-uwsm" else "hyprland");




  # Hyprland system configuration
  environment.etc."hypr/hyprland.conf".text = ''
    # Debug configuration - enable detailed logging to see config errors
    debug {
      disable_logs = false
      enable_stdout_logs = true
    }

    # Monitor configuration - simplified auto-detection
    monitor=,preferred,auto,1

    # Special workspace for "minimized" windows
    workspace = special:minimized, on-created-empty:ghostty

    # Improved window management rules
    windowrulev2 = float, class:^(pavucontrol)$
    windowrulev2 = float, class:^(blueman-manager)$
    windowrulev2 = float, class:^(nm-connection-editor)$
    windowrulev2 = float, class:^(wlogout)$
    windowrulev2 = center, class:^(pavucontrol|blueman-manager|nm-connection-editor)$
    windowrulev2 = size 800 600, class:^(pavucontrol|blueman-manager|nm-connection-editor)$

    # Better focus handling for multiple windows
    windowrulev2 = immediate, class:^(ghostty)$
    windowrulev2 = stayfocused, class:^(rofi)$

    # Workspace configuration
    workspace = 1, default:true
    workspace = 2
    workspace = 3
    workspace = 4
    workspace = 5
    workspace = 6
    workspace = 7
    workspace = 8
    workspace = 9
    workspace = 10

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

    # General settings - Ultimate Modern Design
    general {
        gaps_in = 8
        gaps_out = 24
        border_size = 3
        # Single color border - gradient syntax not supported in v0.51.1
        col.active_border = rgba(7aa2f7ff)
        col.inactive_border = rgba(1a1b2600)  # Invisible for clean look
        layout = dwindle  # Default layout (plugins can override)
        resize_on_border = true
        extend_border_grab_area = 15
        hover_icon_on_border = true
    }

    # Decorations - GNOME-style Modern Aesthetic
    decoration {
        rounding = 8

        # Simplified blur to prevent crashes
        blur {
            enabled = true
            size = 3
            passes = 1
            new_optimizations = true
        }

    }


    # Simple animations to prevent crashes
    animations {
        enabled = true

        bezier = myBezier, 0.05, 0.9, 0.1, 1.05

        animation = windows, 1, 4, myBezier
        animation = windowsOut, 1, 4, default, popin 80%
        animation = border, 1, 8, default
        animation = fade, 1, 4, default
        animation = workspaces, 1, 4, default
    }

    # Dwindle layout - Enhanced tiling
    dwindle {
        pseudotile = true
        preserve_split = true
        smart_split = true
        smart_resizing = true
        force_split = 0
        special_scale_factor = 0.8
        split_width_multiplier = 1.0
        use_active_for_splits = true
    }

    # Window rules - Advanced styling and behavior
    windowrulev2 = float,class:^(pavucontrol)$
    windowrulev2 = float,class:^(blueman-manager)$
    windowrulev2 = float,class:^(nm-applet)$
    windowrulev2 = float,class:^(firefox),title:^(Picture-in-Picture)$

    # Screensaver window rules
    windowrulev2 = fullscreen,class:^(screensaver)$
    windowrulev2 = pin,class:^(screensaver)$
    windowrulev2 = noborder,class:^(screensaver)$

    # Transparency rules for different app types
    windowrulev2 = opacity 0.95 0.85,class:^(ghostty)$
    windowrulev2 = opacity 0.98 0.90,class:^(code)$
    windowrulev2 = opacity 1.0 0.95,class:^(firefox)$

    # Special floating windows with enhanced effects
    windowrulev2 = float,class:^(pwvucontrol)$
    windowrulev2 = size 800 600,class:^(pwvucontrol)$
    windowrulev2 = center,class:^(pwvucontrol)$
    windowrulev2 = opacity 0.95,class:^(pwvucontrol)$

    # Picture-in-picture with special styling
    windowrulev2 = float,title:^(Picture-in-Picture)$
    windowrulev2 = pin,title:^(Picture-in-Picture)$
    windowrulev2 = move 75% 75%,title:^(Picture-in-Picture)$
    windowrulev2 = size 400 225,title:^(Picture-in-Picture)$
    windowrulev2 = opacity 0.95,title:^(Picture-in-Picture)$

    # Workspace-specific rules
    windowrulev2 = workspace 2,class:^(firefox)$
    windowrulev2 = workspace 3,class:^(code)$
    windowrulev2 = workspace 4,class:^(discord)$
    windowrulev2 = workspace 4,class:^(spotify)$



    # Ensure display is on at startup
    exec-once = hyprctl dispatch dpms on

    # Load Hyprland plugins first
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhy3.so"
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhyprexpo.so"
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhyprfocus.so"
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhyprbars.so"
    # exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhyprspace.so"  # disabled: broken with hyprland 0.53+

    # Auto-restore previous session on login (if session file exists)
    exec-once = [ -f ~/.config/hypr/session.json ] && sleep 3 && hyprctl dispatch restoresession ~/.config/hypr/session.json

    # Kill any duplicate applets that might autostart
    exec-once = pkill nm-applet || true
    exec-once = pkill blueman-applet || true
    exec-once = pkill waybar || true

    # Waybar autostart
    exec-once = sleep 2 && waybar > /tmp/waybar.log 2>&1

    # nwg-dock-hyprland for window management and dock experience
    exec-once = sleep 3 && nwg-dock-hyprland

    # Smart notification system
    exec-once = sleep 1 && dunst &


    # Hypridle for advanced idle management (managed by systemd service)

    # Clipboard history management
    exec-once = wl-paste --type text --watch cliphist store
    exec-once = wl-paste --type image --watch cliphist store

    # Session management - auto-save every 10 minutes for crash recovery
    exec-once = mkdir -p ~/.config/hypr
    exec-once = while true; do sleep 600; hyprctl dispatch savesession ~/.config/hypr/session.json; done &

    # Source plugin configurations
  '';


  # Wlogout configuration (beautiful graphical power menu)
  environment.etc."xdg/wlogout/layout".text = ''
    {
        "label" : "lock",
        "action" : "hyprlock",
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
        "action" : "bash -c 'hyprctl dispatch exit; sleep 1; loginctl terminate-session \"\"'",
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

  # Hyprlock configuration (ultimate modern lock screen)
  environment.etc."hypr/hyprlock.conf".text = ''
    # Ultimate Modern Hyprlock Configuration

    # General settings
    general {
        disable_loading_bar = true
        grace = 2
        hide_cursor = true
        no_fade_in = false
        no_fade_out = false
        ignore_empty_input = false
    }

    # Dynamic background with blur
    background {
        monitor =
        path = /tmp/hyprlock-wallpaper.png
        blur_passes = 3
        blur_size = 8
        noise = 0.0117
        contrast = 0.8916
        brightness = 0.8172
        vibrancy = 0.1696
        vibrancy_darkness = 0.0
    }

    # Input field styling
    input-field {
        monitor =
        size = 350, 60
        outline_thickness = 2
        dots_size = 0.26
        dots_spacing = 0.64
        dots_center = true
        dots_rounding = -1
        outer_color = rgba(0, 122, 255, 0.8)
        inner_color = rgba(255, 255, 255, 0.9)
        font_color = rgba(28, 28, 30, 1.0)
        fade_on_empty = true
        fade_timeout = 1000
        placeholder_text = "Enter Password"
        font_family = "Inter"
        font_size = 16

        position = 0, -120
        halign = center
        valign = center

        shadow_passes = 2
        shadow_size = 3.5
        shadow_color = rgba(0, 0, 0, 0.3)
        shadow_boost = 1.2

        rounding = 16
        fail_color = rgba(255, 69, 58, 1.0)
        fail_text = "Authentication Failed"
        fail_timeout = 2000
        fail_transitions = 300

        capslock_color = rgba(255, 204, 0, 1.0)
        numlock_color = rgba(52, 199, 89, 1.0)
        bothlock_color = rgba(175, 82, 222, 1.0)
        invert_numlock = false
        swap_font_color = false
    }

    # Clock with modern styling
    label {
        monitor =
        text = cmd[update:1000] echo $(date +%H:%M)
        color = rgba(28, 28, 30, 1.0)
        font_size = 120
        font_family = "Inter Bold"
        shadow_passes = 3
        shadow_size = 4
        shadow_color = rgba(0, 0, 0, 0.6)
        shadow_boost = 1.5

        position = 0, 150
        halign = center
        valign = center
    }

    # Date label
    label {
        monitor =
        text = cmd[update:1000] echo $(date)
        color = rgba(72, 72, 74, 0.8)
        font_size = 24
        font_family = "Inter Medium"

        position = 0, 50
        halign = center
        valign = center

        shadow_passes = 2
        shadow_size = 2
        shadow_color = rgba(0, 0, 0, 0.4)
    }

    # Username label
    label {
        monitor =
        text = Hi, $USER
        color = rgba(28, 28, 30, 0.9)
        font_size = 28
        font_family = "Inter SemiBold"

        position = 0, -200
        halign = center
        valign = center

        shadow_passes = 2
        shadow_size = 2
        shadow_color = rgba(0, 0, 0, 0.4)
    }

    # System info
    label {
        monitor =
        text = cmd[update:5000] echo perdurabo
        color = rgba(0, 122, 255, 0.7)
        font_size = 16
        font_family = "Inter Regular"

        position = 30, 30
        halign = left
        valign = bottom
    }

    # Desktop indicator
    label {
        monitor =
        text = 🖥️ Desktop System
        color = rgba(52, 199, 89, 0.7)
        font_size = 16
        font_family = "Inter Regular"

        position = -30, 30
        halign = right
        valign = bottom
    }
  '';

  # Hypridle configuration (desktop power management)
  environment.etc."hypr/hypridle.conf".text = ''
    # Desktop Hypridle Configuration
    # https://wiki.hypr.land/Hypr-Ecosystem/hypridle/

    general {
        lock_cmd = pidof hyprlock || hyprlock       # DBus lock command
        unlock_cmd = notify-send "Welcome back!"    # DBus unlock command
        before_sleep_cmd = loginctl lock-session    # Before system sleep
        after_sleep_cmd = hyprctl dispatch dpms on  # After system sleep
        ignore_dbus_inhibit = false                 # Don't ignore DBus inhibit
        ignore_systemd_inhibit = false              # Don't ignore systemd inhibit
    }

    # Lock screen after 5 minutes of inactivity
    listener {
        timeout = 300
        on-timeout = hyprlock
    }

    # Turn off monitor after 10 minutes
    listener {
        timeout = 600
        on-timeout = hyprctl dispatch dpms off
        on-resume = hyprctl dispatch dpms on
    }

    # Suspend system after 30 minutes
    listener {
        timeout = 1800
        on-timeout = systemctl suspend
    }
    }
  '';


  environment.etc."swaylock/config".text = ''
    # Appearance
    color=1a1b26
    font=JetBrains Mono
    font-size=24

    # Effects
    effect-blur=20x3
    effect-vignette=0.2:0.5
    fade-in=0.2
    grace=2

    # Ring
    ring-color=32344a
    ring-clear-color=f7768e
    ring-caps-lock-color=e0af68
    ring-ver-color=7aa2f7
    ring-wrong-color=f7768e

    # Key highlight
    key-hl-color=bb9af7

    # Line (separator)
    line-color=00000000
    line-clear-color=00000000
    line-caps-lock-color=00000000
    line-ver-color=00000000
    line-wrong-color=00000000

    # Inside
    inside-color=1a1b2688
    inside-clear-color=f7768e88
    inside-caps-lock-color=e0af6888
    inside-ver-color=7aa2f788
    inside-wrong-color=f7768e88

    # Text
    text-color=c0caf5
    text-clear-color=1a1b26
    text-caps-lock-color=1a1b26
    text-ver-color=1a1b26
    text-wrong-color=1a1b26

    # Layout
    indicator
    indicator-radius=100
    indicator-thickness=10

    # Clock
    clock
    timestr=%H:%M
    datestr=%A, %B %d

    # Positioning
    indicator-x-position=960
    indicator-y-position=540
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
      background-image: image(url("/run/current-system/sw/share/wlogout/icons/lock.png"));
      border-color: #f7768e;
    }

    #logout {
      background-image: image(url("/run/current-system/sw/share/wlogout/icons/logout.png"));
      border-color: #e0af68;
    }

    #suspend {
      background-image: image(url("/run/current-system/sw/share/wlogout/icons/suspend.png"));
      border-color: #9ece6a;
    }

    #hibernate {
      background-image: image(url("/run/current-system/sw/share/wlogout/icons/hibernate.png"));
      border-color: #7dcfff;
    }

    #shutdown {
      background-image: image(url("/run/current-system/sw/share/wlogout/icons/shutdown.png"));
      border-color: #bb9af7;
    }

    #reboot {
      background-image: image(url("/run/current-system/sw/share/wlogout/icons/reboot.png"));
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

  # Required for Hyprland
  security.polkit.enable = true;

  # XDG portal configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };


  # Enable X11 support for SDDM
  services.xserver.enable = true;

  # Essential Hyprland packages (cleaned up)
  environment.systemPackages = with pkgs; [
    # Core Wayland utilities
    wl-clipboard
    wlr-randr
    grim
    slurp
    swayidle
    hyprlock       # Ultimate modern Hyprland-native lock screen
    hypridle       # Idle management for Hyprland
    swaybg
    wlogout

    # System utilities (dunst installed by dunst.nix module)
    libnotify
    pamixer
    xdg-user-dirs
    libcanberra
    brightnessctl       # Screen brightness control for idle dimming
    imagemagick  # For dynamic wallpaper generation
    socat        # For Hyprland event monitoring
    cmatrix      # Matrix screensaver

    # Applications (rofi installed by rofi.nix module)
    ghostty            # Modern GPU-accelerated terminal
    kitty
    flameshot          # Screenshot tool
    waybar             # Modern status bar

    # SDDM themes and icons (kept for theme compatibility)
    kdePackages.breeze
    kdePackages.breeze-icons
    kdePackages.breeze-gtk

    # Qt5 compatibility for SDDM astronaut theme
    qt5.qtgraphicaleffects
    qt5.qtquickcontrols2
    qt5.qtsvg
  ];

  # Systemd user service for hypridle - only when GNOME is not enabled
  systemd.user.services.hypridle = lib.mkIf (!config.services.desktopManager.gnome.enable) {
    description = "Hypridle idle management for Hyprland";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.hypridle}/bin/hypridle";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Enable required services
  services = {
    dbus.enable = lib.mkDefault true;
    gnome.gnome-keyring.enable = true;
    upower.enable = lib.mkDefault (!config.services.desktopManager.gnome.enable);
  };

  # Disable duplicate applets (nwg-panel handles these)
  systemd.user.services.nm-applet.enable = false;
  systemd.user.services.blueman-applet.enable = false;

  # Fix PAM configuration for gnome-keyring to resolve challenge-response errors
  security.pam.services = {
    login.enableGnomeKeyring = true;
    sddm.enableGnomeKeyring = true;
    sddm-greeter.enableGnomeKeyring = true;
    passwd.enableGnomeKeyring = true;
  };
}