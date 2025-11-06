# Ultimate Modern Waybar Configuration - macOS Sonoma Style
{ config, pkgs, lib, ... }:

{
  # Install waybar but don't enable globally (will be started by Hyprland only)
  # programs.waybar.enable = true;

  # Install required dependencies for waybar modules
  environment.systemPackages = with pkgs; [
    # Waybar itself (for Hyprland only)
    waybar

    # Waybar dependencies
    rofi          # Application launcher (for custom/logo on-click)
    wlogout       # Logout menu (for custom/power)

    # Icon themes for tray icons
    adwaita-icon-theme
    hicolor-icon-theme

    # Network and system utilities
    networkmanager
    networkmanagerapplet
    pavucontrol
    pwvucontrol  # PipeWire volume control
    # System monitoring
    htop
    btop
    # Required for waybar modules
    playerctl  # Media control
    jq         # JSON processing for waybar
  ];

  # Waybar configuration
  environment.etc."xdg/waybar/config".text = builtins.toJSON {
    layer = "top";
    position = "top";
    height = 50;
    spacing = 8;
    margin-top = 8;
    margin-left = 16;
    margin-right = 16;

    modules-left = [
      "custom/logo"
      "hyprland/workspaces"
      "hyprland/window"
    ];

    modules-center = [
      "clock"
    ];

    modules-right = [
      "tray"
      "pulseaudio"
      "network"
      "cpu"
      "memory"
      "custom/power"
    ];

    # Module configurations
    "custom/logo" = {
      format = "❄️";
      tooltip = false;
      on-click = "rofi -show drun";
      on-click-right = "wlogout --layer-shell";
    };

    "hyprland/workspaces" = {
      format = "{name}";
      format-icons = {
        "1" = "󰎤";
        "2" = "󰎧";
        "3" = "󰎪";
        "4" = "󰎭";
        "5" = "󰎱";
        "6" = "󰎳";
        "7" = "󰎶";
        "8" = "󰎹";
        "9" = "󰎼";
        "10" = "󰽥";
        default = "󰧞";
        urgent = "󱈸";
      };
      on-click = "activate";
      show-special = false;
      sort-by-number = true;
      active-only = false;
    };

    "hyprland/window" = {
      format = "{}";
      max-length = 50;
      separate-outputs = true;
      rewrite = {
        "^$" = "Desktop";
      };
    };

    clock = {
      format = "{:%H:%M}";
      format-alt = "{:%A, %B %d, %Y}";
      tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      actions = {
        on-click-right = "mode";
        on-click-forward = "tz_up";
        on-click-backward = "tz_down";
        on-scroll-up = "shift_up";
        on-scroll-down = "shift_down";
      };
      calendar = {
        mode = "year";
        mode-mon-col = 3;
        weeks-pos = "right";
        on-scroll = 1;
        format = {
          months = "<span color='#1C1C1E'><b>{}</b></span>";
          days = "<span color='#48484A'><b>{}</b></span>";
          weeks = "<span color='#007AFF'><b>W{}</b></span>";
          weekdays = "<span color='#34C759'><b>{}</b></span>";
          today = "<span color='#FF3B30'><b><u>{}</u></b></span>";
        };
      };
    };

    tray = {
      icon-size = 18;
      spacing = 12;
      show-passive-items = true;
    };

    pulseaudio = {
      format = "{icon} {volume}%";
      format-muted = "󰝟 Muted";
      format-icons = {
        headphone = "󰋋";
        hands-free = "󱡏";
        headset = "󰋎";
        phone = "󰏲";
        portable = "󰦧";
        car = "󰄋";
        default = ["󰕿" "󰖀" "󰕾"];
      };
      scroll-step = 5;
      on-click = "pwvucontrol";
      on-click-right = "pavucontrol";
      tooltip-format = "{desc}";
    };

    network = {
      format-wifi = "󰤨 {signalStrength}%";
      format-ethernet = "󰈀 Connected";
      format-disconnected = "󰤭 Disconnected";
      tooltip-format = "{ifname}: {ipaddr}";
      tooltip-format-wifi = "{essid} ({signalStrength}%): {ipaddr}";
      on-click = "nm-connection-editor";
      max-length = 20;
    };

    cpu = {
      format = "󰻠 {usage}%";
      tooltip = true;
      interval = 2;
      states = {
        warning = 70;
        critical = 90;
      };
    };

    memory = {
      format = "󰍛 {percentage}%";
      tooltip-format = "{used:0.1f}G / {total:0.1f}G used";
      states = {
        warning = 70;
        critical = 90;
      };
    };

    "custom/power" = {
      format = "󰤆";
      tooltip = false;
      on-click = "wlogout --layer-shell";
      on-click-right = "hyprlock";
    };
  };

  # Ultimate Modern CSS Styling - macOS Sonoma
  environment.etc."xdg/waybar/style.css".text = ''
    /* Ultimate Modern Glassmorphism Waybar Theme - macOS Sonoma */
    * {
      border: none;
      border-radius: 0;
      font-family: "Inter", "SF Pro Display", "JetBrains Mono Nerd Font", sans-serif;
      font-weight: 500;
      font-size: 14px;
      min-height: 0;
      margin: 0;
      padding: 0;
    }

    window#waybar {
      background: linear-gradient(135deg,
        rgba(242, 242, 247, 0.12) 0%,
        rgba(255, 255, 255, 0.18) 25%,
        rgba(248, 248, 248, 0.15) 50%,
        rgba(255, 255, 255, 0.18) 75%,
        rgba(242, 242, 247, 0.12) 100%);
      -webkit-backdrop-filter: blur(40px) saturate(180%) brightness(110%);
      border: 1px solid rgba(0, 122, 255, 0.15);
      border-radius: 24px;
      color: rgba(28, 28, 30, 0.9);
      box-shadow:
        0 8px 32px rgba(0, 0, 0, 0.15),
        0 2px 16px rgba(0, 122, 255, 0.08),
        inset 0 1px 0 rgba(255, 255, 255, 0.4),
        inset 0 -1px 0 rgba(0, 0, 0, 0.05);
      transition: all 0.3s cubic-bezier(0.4, 0.0, 0.2, 1);
    }

    window#waybar.hidden {
      opacity: 0.2;
    }

    /* Floating island effect */
    .modules-left,
    .modules-center,
    .modules-right {
      background: transparent;
      margin: 4px;
    }

    /* Custom logo/launcher */
    #custom-logo {
      font-size: 18px;
      color: rgba(0, 122, 255, 1.0);
      background: rgba(0, 122, 255, 0.1);
      border-radius: 12px;
      padding: 6px 12px;
      margin: 4px;
      transition: all 0.3s ease;
    }

    #custom-logo:hover {
      background: rgba(0, 122, 255, 0.2);
      box-shadow: 0 4px 12px rgba(0, 122, 255, 0.3);
    }

    /* Workspaces */
    #workspaces {
      background: rgba(255, 255, 255, 0.1);
      border-radius: 16px;
      padding: 2px 8px;
      margin: 4px;
    }

    #workspaces button {
      padding: 4px 8px;
      margin: 2px;
      border-radius: 8px;
      color: rgba(72, 72, 74, 0.8);
      background: transparent;
      transition: all 0.3s ease;
    }

    #workspaces button.active {
      background: rgba(0, 122, 255, 0.8);
      color: rgba(255, 255, 255, 1.0);
      box-shadow: 0 2px 8px rgba(0, 122, 255, 0.4);
    }

    #workspaces button:hover {
      background: rgba(0, 122, 255, 0.3);
      color: rgba(28, 28, 30, 1.0);
    }

    /* Window title */
    #window {
      color: rgba(28, 28, 30, 0.8);
      font-weight: 600;
      padding: 6px 12px;
      background: rgba(255, 255, 255, 0.08);
      border-radius: 12px;
      margin: 4px;
    }

    /* Clock */
    #clock {
      font-weight: 600;
      font-size: 15px;
      color: rgba(28, 28, 30, 0.9);
      background: rgba(255, 255, 255, 0.15);
      border-radius: 12px;
      padding: 6px 16px;
      margin: 4px;
      transition: all 0.3s ease;
    }

    #clock:hover {
      background: rgba(255, 255, 255, 0.25);
    }

    /* System modules */
    #cpu,
    #memory,
    #network,
    #pulseaudio,
    #tray,
    #custom-power {
      background: rgba(255, 255, 255, 0.1);
      border-radius: 12px;
      padding: 6px 12px;
      margin: 2px;
      color: rgba(28, 28, 30, 0.8);
      transition: all 0.3s ease;
    }

    #cpu:hover,
    #memory:hover,
    #network:hover,
    #pulseaudio:hover {
      background: rgba(255, 255, 255, 0.2);
    }

    /* CPU states */
    #cpu.warning {
      background: rgba(255, 204, 0, 0.2);
      color: rgba(255, 149, 0, 1.0);
    }

    #cpu.critical {
      background: rgba(255, 69, 58, 0.2);
      color: rgba(255, 69, 58, 1.0);
    }

    /* Memory states */
    #memory.warning {
      background: rgba(255, 204, 0, 0.2);
      color: rgba(255, 149, 0, 1.0);
    }

    #memory.critical {
      background: rgba(255, 69, 58, 0.2);
      color: rgba(255, 69, 58, 1.0);
    }

    /* Network states */
    #network.disconnected {
      background: rgba(255, 69, 58, 0.2);
      color: rgba(255, 69, 58, 1.0);
    }

    /* Audio */
    #pulseaudio.muted {
      color: rgba(142, 142, 147, 0.8);
    }

    /* Tray */
    #tray > .passive {
      -gtk-icon-effect: dim;
    }

    #tray > .needs-attention {
      -gtk-icon-effect: highlight;
      background-color: rgba(255, 69, 58, 0.2);
    }

    /* Power button */
    #custom-power {
      color: rgba(255, 69, 58, 0.9);
      font-size: 16px;
    }

    #custom-power:hover {
      background: rgba(255, 69, 58, 0.2);
      color: rgba(255, 69, 58, 1.0);
    }

    /* Animation effects */
    @keyframes pulse {
      0% { box-shadow: 0 0 0 0 rgba(0, 122, 255, 0.4); }
      70% { box-shadow: 0 0 0 10px rgba(0, 122, 255, 0); }
      100% { box-shadow: 0 0 0 0 rgba(0, 122, 255, 0); }
    }

    /* Smooth transitions for all interactive elements */
    button,
    #custom-logo,
    #clock,
    #cpu,
    #memory,
    #network,
    #pulseaudio,
    #custom-power {
      transition: all 0.3s cubic-bezier(0.4, 0.0, 0.2, 1);
    }
  '';
}