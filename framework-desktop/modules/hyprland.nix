# Hyprland configuration
{ config, pkgs, lib, inputs, ... }:

{
  # Enable Hyprland
  programs.hyprland = {
    enable = true;
  };

  # Hyprland system configuration
  environment.etc."hypr/hyprland.conf".text = ''
    # Monitor configuration - Framework Desktop with dual displays
    # Based on detected displays: DP-10, DP-11 (connected), HDMI-A-1 (connected)
    monitor=DP-10,1920x1080@60,0x0,1
    monitor=DP-11,1920x1080@60,1920x0,1
    monitor=HDMI-A-1,disable  # Disable HDMI if using DP monitors
    # Alternatively, if using HDMI instead of one DP:
    # monitor=HDMI-A-1,1920x1080@60,1920x0,1

    # Input configuration
    input {
        kb_layout = us
        follow_mouse = 1
        touchpad {
            natural_scroll = true
        }
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
    bind = $mod, Q, killactive
    bind = $mod, M, exit
    bind = $mod, V, togglefloating
    bind = $mod, R, exec, wofi --show drun
    bind = $mod, P, pseudo
    bind = $mod, J, togglesplit

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

    # Autostart
    exec-once = waybar
    exec-once = dunst
    exec-once = nm-applet
    exec-once = blueman-applet
  '';

  # Waybar configuration
  environment.etc."xdg/waybar/config".text = builtins.toJSON {
    layer = "top";
    position = "top";
    height = 30;

    modules-left = [ "hyprland/workspaces" "hyprland/mode" ];
    modules-center = [ "hyprland/window" ];
    modules-right = [ "pulseaudio" "network" "cpu" "memory" "temperature" "backlight" "battery" "clock" "tray" ];

    "hyprland/workspaces" = {
      disable-scroll = true;
      all-outputs = true;
      format = "{icon}";
      format-icons = {
        "1" = "1";
        "2" = "2";
        "3" = "3";
        "4" = "4";
        "5" = "5";
        urgent = "";
        focused = "";
        default = "";
      };
    };

    clock = {
      tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      format-alt = "{:%Y-%m-%d}";
    };

    cpu = {
      format = "{usage}% ";
      tooltip = false;
    };

    memory = {
      format = "{}% ";
    };

    temperature = {
      critical-threshold = 80;
      format = "{temperatureC}°C {icon}";
      format-icons = ["" "" ""];
    };

    backlight = {
      format = "{percent}% {icon}";
      format-icons = ["" "" "" "" "" "" "" "" ""];
    };

    battery = {
      states = {
        warning = 30;
        critical = 15;
      };
      format = "{capacity}% {icon}";
      format-charging = "{capacity}% ";
      format-plugged = "{capacity}% ";
      format-alt = "{time} {icon}";
      format-icons = ["" "" "" "" ""];
    };

    network = {
      format-wifi = "{essid} ({signalStrength}%) ";
      format-ethernet = "{ipaddr}/{cidr} ";
      tooltip-format = "{ifname} via {gwaddr} ";
      format-linked = "{ifname} (No IP) ";
      format-disconnected = "Disconnected ⚠";
      format-alt = "{ifname}: {ipaddr}/{cidr}";
    };

    pulseaudio = {
      format = "{volume}% {icon} {format_source}";
      format-bluetooth = "{volume}% {icon} {format_source}";
      format-bluetooth-muted = " {icon} {format_source}";
      format-muted = " {format_source}";
      format-source = "{volume}% ";
      format-source-muted = "";
      format-icons = {
        headphone = "";
        hands-free = "";
        headset = "";
        phone = "";
        portable = "";
        car = "";
        default = ["" "" ""];
      };
      on-click = "pavucontrol";
    };
  };

  # Waybar CSS styling
  environment.etc."xdg/waybar/style.css".text = ''
    * {
      border: none;
      border-radius: 0;
      font-family: "Fira Code", monospace;
      font-size: 13px;
      min-height: 0;
    }

    window#waybar {
      background: rgba(43, 48, 59, 0.95);
      border-bottom: 3px solid rgba(100, 114, 125, 0.5);
      color: #ffffff;
    }

    .modules-left > widget:first-child > #workspaces {
      margin-left: 0;
    }

    .modules-right > widget:last-child > #workspaces {
      margin-right: 0;
    }

    #workspaces button {
      padding: 0 5px;
      background-color: transparent;
      color: #ffffff;
      border-bottom: 3px solid transparent;
    }

    #workspaces button:hover {
      background: rgba(0, 0, 0, 0.2);
      box-shadow: inset 0 -3px #ffffff;
    }

    #workspaces button.focused {
      background-color: #64727d;
      border-bottom: 3px solid #ffffff;
    }

    #workspaces button.urgent {
      background-color: #eb4d4b;
    }

    #mode {
      background-color: #64727d;
      border-bottom: 3px solid #ffffff;
    }

    #clock,
    #battery,
    #cpu,
    #memory,
    #temperature,
    #backlight,
    #network,
    #pulseaudio,
    #tray,
    #mode,
    #idle_inhibitor,
    #mpd {
      padding: 0 10px;
      margin: 0 4px;
      color: #ffffff;
    }

    #window,
    #workspaces {
      margin: 0 4px;
    }

    #clock {
      background-color: #64727d;
    }

    #battery {
      background-color: #ffffff;
      color: #000000;
    }

    #battery.charging {
      color: #ffffff;
      background-color: #26a65b;
    }

    @keyframes blink {
      to {
        background-color: #ffffff;
        color: #000000;
      }
    }

    #battery.critical:not(.charging) {
      background-color: #f53c3c;
      color: #ffffff;
      animation-name: blink;
      animation-duration: 0.5s;
      animation-timing-function: linear;
      animation-iteration-count: infinite;
      animation-direction: alternate;
    }

    #cpu {
      background-color: #2ecc71;
      color: #000000;
    }

    #memory {
      background-color: #9b59b6;
    }

    #backlight {
      background-color: #90b1b1;
    }

    #network {
      background-color: #2980b9;
    }

    #network.disconnected {
      background-color: #f53c3c;
    }

    #pulseaudio {
      background-color: #f1c40f;
      color: #000000;
    }

    #pulseaudio.muted {
      background-color: #90b1b1;
      color: #2a5c45;
    }

    #temperature {
      background-color: #f0932b;
    }

    #temperature.critical {
      background-color: #eb4d4b;
    }

    #tray {
      background-color: #2980b9;
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
      xdg-desktop-portal-gtk
    ];
  };

  # Fonts for Hyprland
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    font-awesome
    dejavu_fonts
    open-sans
    roboto
    material-design-icons
    dina-font
    proggyfonts
  ];

  # Essential Hyprland packages
  environment.systemPackages = with pkgs; [
    # Wayland utilities
    wl-clipboard
    wlr-randr
    waybar
    wofi
    dunst
    grim
    slurp
    swayidle
    swaylock-effects

    # File manager
    xfce.thunar

    # Terminal
    kitty

    # Application launcher
    rofi-wayland

    # Screenshot tools
    flameshot

    # Brightness control
    brightnessctl

    # Audio control
    pamixer

    # Network applet
    networkmanagerapplet

    # Bluetooth applet
    blueman
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
  };

  # Enable touchpad support
  services.libinput.enable = true;
}