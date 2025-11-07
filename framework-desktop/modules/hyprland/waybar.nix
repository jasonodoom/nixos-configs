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
    rofi-wayland  # Application launcher (for custom/logo on-click)
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

  # Waybar configuration - ZaneyOS ddubs style
  environment.etc."xdg/waybar/config".text = builtins.toJSON {
    layer = "top";
    position = "top";

    modules-left = [
      "custom/logo"
      "hyprland/window"
    ];

    modules-center = [
      "hyprland/workspaces"
    ];

    modules-right = [
      "network"
      "wireplumber"
      "cpu"
      "memory"
      "idle_inhibitor"
      "mpris"
      "custom/keybindings"
      "tray"
      "custom/power"
      "clock"
    ];

    # Module configurations
    "custom/logo" = {
      format = "";
      tooltip = false;
      font-size = 22;
      on-click = "rofi -show drun";
      on-click-right = "wlogout --layer-shell";
    };

    "hyprland/workspaces" = {
      format = "{name}";
      format-icons = {
        default = " ";
        active = " ";
        urgent = " ";
      };
      on-scroll-up = "hyprctl dispatch workspace e+1";
      on-scroll-down = "hyprctl dispatch workspace e-1";
    };

    "hyprland/window" = {
      max-length = 22;
      separate-outputs = false;
      rewrite = {
        "" = " 🙈 No Windows? ";
      };
    };

    "custom/keybindings" = {
      tooltip = false;
      format = "󱕴";
      on-click = "rofi -show keys";
    };

    clock = {
      format = "{:%I:%M %p}";
      format-alt = "{:%A, %B %d, %Y}";
      tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      actions = {
        on-click = "tz_up";
        on-click-right = "mode";
      };
      calendar = {
        mode = "month";
        mode-mon-col = 3;
        weeks-pos = "right";
        on-scroll = 1;
        format = {
          months = "<span color='#7aa2f7'><b>{}</b></span>";
          days = "<span color='#c0caf5'><b>{}</b></span>";
          weeks = "<span color='#bb9af7'><b>W{}</b></span>";
          weekdays = "<span color='#9ece6a'><b>{}</b></span>";
          today = "<span color='#f7768e'><b><u>{}</u></b></span>";
        };
      };
    };

    tray = {
      icon-size = 18;
      spacing = 12;
      show-passive-items = true;
    };

    idle_inhibitor = {
      format = "{icon}";
      format-icons = {
        activated = "󰅶";
        deactivated = "󰾪";
      };
      tooltip-format-activated = "Idle inhibitor active";
      tooltip-format-deactivated = "Idle inhibitor inactive";
    };

    mpris = {
      format = "{player_icon} {dynamic}";
      format-paused = "{status_icon} {dynamic}";
      player-icons = {
        default = "🎵";
        mpv = "🎵";
        spotify = "";
      };
      status-icons = {
        paused = "⏸";
        playing = "▶";
      };
      ignored-players = ["firefox"];
      max-length = 40;
    };

    wireplumber = {
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
      scroll-step = 2;
      on-click = "playerctl play-pause";
      on-click-right = "pwvucontrol";
      on-click-middle = "pavucontrol";
      tooltip-format = "{desc} • Click to play/pause";
      max-volume = 150;
    };

    network = {
      format-wifi = " {essid}";
      format-ethernet = "󰈀 {ipaddr}";
      format-linked = "󰈀 {ifname} (No IP)";
      format-disconnected = "󰌙 Disconnected";
      format-alt = "{ifname}: {ipaddr}/{cidr}";
      tooltip-format = "{ifname} via {gwaddr}";
      tooltip-format-wifi = "{essid} ({signalStrength}%): {ipaddr}";
      tooltip-format-ethernet = "{ifname}: {ipaddr}";
      tooltip-format-disconnected = "Disconnected";
      on-click = "nm-connection-editor";
      max-length = 30;
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

  # ZaneyOS ddubs Style - Modern rounded rectangles
  # https://gitlab.com/Zaney/zaneyos/
  environment.etc."xdg/waybar/style.css".text = ''
    * {
      border: none;
      border-radius: 0px;
      font-family: "JetBrains Mono Nerd Font", sans-serif;
      font-size: 18px;
      min-height: 0px;
    }

    window#waybar {
      background: rgba(0, 0, 0, 0);
    }

    #workspaces {
      color: #1a1b26;
      background: #32344a;
      margin: 4px 4px;
      padding: 5px 5px;
      border-radius: 16px;
    }

    #workspaces button {
      font-weight: bold;
      padding: 0px 5px;
      margin: 0px 3px;
      border-radius: 16px;
      color: #1a1b26;
      background: linear-gradient(45deg, #f7768e, #7aa2f7);
      opacity: 0.5;
      transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
    }

    #workspaces button.active {
      font-weight: bold;
      padding: 0px 5px;
      margin: 0px 3px;
      border-radius: 16px;
      color: #1a1b26;
      background: linear-gradient(45deg, #f7768e, #7aa2f7);
      transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
      opacity: 1.0;
      min-width: 40px;
    }

    #workspaces button:hover {
      font-weight: bold;
      border-radius: 16px;
      color: #1a1b26;
      background: linear-gradient(45deg, #f7768e, #7aa2f7);
      opacity: 0.8;
      transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
    }

    tooltip {
      background: #1a1b26;
      border: 1px solid #f7768e;
      border-radius: 12px;
    }

    tooltip label {
      color: #f7768e;
    }

    #window, #wireplumber, #cpu, #memory, #idle_inhibitor {
      font-weight: bold;
      margin: 4px 0px;
      margin-left: 7px;
      padding: 0px 18px;
      background: #1a1b26;
      color: #f7768e;
      border-radius: 8px 8px 8px 8px;
    }

    #idle_inhibitor {
      font-size: 28px;
    }

    #custom-logo {
      color: #9ece6a;
      background: #32344a;
      font-size: 22px;
      margin: 0px;
      padding: 0px 5px 0px 5px;
      border-radius: 16px 16px 16px 16px;
    }

    #network, #custom-keybindings, #mpris, #tray, #custom-power {
      font-size: 20px;
      background: #1a1b26;
      color: #f7768e;
      margin: 4px 0px;
      margin-right: 7px;
      border-radius: 8px 8px 8px 8px;
      padding: 0px 18px;
    }

    #clock {
      font-weight: bold;
      font-size: 16px;
      color: #0D0E15;
      background: linear-gradient(90deg, #9ece6a, #32344a);
      margin: 0px;
      padding: 0px 5px 0px 5px;
      border-radius: 16px 16px 16px 16px;
    }

  '';
}