# Waybar status bar configuration
{ config, pkgs, ... }:

{
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
      tooltip-format = "<big>{:%Y %B}</big>\\n<tt><small>{calendar}</small></tt>";
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

  # Ensure waybar package is available
  environment.systemPackages = with pkgs; [
    waybar
  ];
}