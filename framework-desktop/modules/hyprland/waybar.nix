# Modern waybar configuration inspired by BA_usr's dotfiles
{ config, pkgs, ... }:

{
  # Enhanced waybar configuration
  environment.etc."xdg/waybar/config".text = builtins.toJSON {
    layer = "top";
    position = "top";
    height = 48;
    spacing = 4;

    modules-left = [ "custom/os" "hyprland/workspaces" "custom/separator" ];
    modules-center = [ "hyprland/window" ];
    modules-right = [ "bluetooth" "network" "pulseaudio" "cpu" "memory" "temperature" "clock" ];

    "custom/os" = {
      format = " ";
      tooltip-format = "Click to open applications";
      on-click = "rofi -show drun";
      tooltip = true;
    };

    "custom/separator" = {
      format = "|";
      tooltip = false;
    };

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
        "6" = "6";
        "7" = "7";
        "8" = "8";
        "9" = "9";
        "10" = "10";
        urgent = "";
        focused = "";
        default = "";
      };
      persistent_workspaces = {
        "1" = [];
        "2" = [];
        "3" = [];
        "4" = [];
        "5" = [];
      };
    };

    "hyprland/window" = {
      format = "{}";
      max-length = 50;
    };

    clock = {
      interval = 60;
      format = "{:%H:%M}";
      format-alt = "{:%Y-%m-%d}";
      tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
    };

    cpu = {
      format = "󰻠 {usage}%";
      tooltip = false;
      interval = 2;
    };

    memory = {
      format = "󰍛 {}%";
      interval = 2;
    };

    temperature = {
      thermal-zone = 2;
      hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
      critical-threshold = 80;
      format-critical = "🌡️ {temperatureC}°C";
      format = "🌡️ {temperatureC}°C";
    };

    network = {
      format-wifi = "󰤨 {signalStrength}%";
      format-ethernet = "󰈀 {essid}";
      tooltip-format-wifi = "WiFi: {essid}\nSignal: {signalStrength}%\nIP: {ipaddr}";
      tooltip-format-ethernet = "Ethernet: {ifname}\nIP: {ipaddr}/{cidr}";
      tooltip-format-disconnected = "Disconnected";
      format-linked = "󰈀 No IP";
      format-disconnected = "󰤮 Off";
      format-alt = "{ipaddr}";
      interval = 2;
      on-click = "nm-connection-editor";
      max-length = 50;
    };

    pulseaudio = {
      format = "{icon} {volume}%";
      format-bluetooth = "{icon} {volume}%";
      format-bluetooth-muted = "󰝟 {icon}";
      format-muted = "󰝟";
      format-source = "{volume}% ";
      format-source-muted = "";
      format-icons = {
        headphone = "󰋋";
        hands-free = "󰋎";
        headset = "󰋎";
        phone = "";
        portable = "";
        car = "";
        default = ["󰕿" "󰖀" "󰕾"];
      };
      on-click = "pavucontrol";
      on-click-right = "pamixer --toggle-mute";
      on-scroll-up = "pamixer -i 5";
      on-scroll-down = "pamixer -d 5";
      scroll-step = 5;
      tooltip-format = "Volume: {volume}%\nLeft click: Open mixer\nRight click: Toggle mute\nScroll: Adjust volume";
    };

    bluetooth = {
      format = "󰂯 {status}";
      format-disabled = "󰂲 Off";
      format-off = "󰂲 Off";
      format-on = "󰂯 On";
      format-connected = "󰂱 {device_alias}";
      format-connected-battery = "󰂱 {device_alias} {device_battery_percentage}%";
      tooltip-format = "{controller_alias}\t{controller_address}\n{num_connections} connected";
      tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
      tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
      tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
      on-click = "blueman-manager";
      max-length = 50;
    };

  };

  # Modern CSS styling inspired by BA_usr
  environment.etc."xdg/waybar/style.css".text = ''
    * {
      border: none;
      border-radius: 0;
      font-family: "JetBrains Mono Nerd Font", "Material Design Icons", monospace;
      font-weight: 500;
      font-size: 14px;
      min-height: 0;
    }

    window#waybar {
      background-color: rgba(30, 30, 46, 0.9);
      color: #cdd6f4;
      transition: all 0.3s ease;
      border-bottom: 2px solid rgba(116, 199, 236, 0.3);
    }

    tooltip {
      background: rgba(17, 17, 27, 0.95);
      border: 1px solid rgba(116, 199, 236, 0.5);
      border-radius: 10px;
      color: #cdd6f4;
      font-size: 13px;
    }

    #workspaces {
      margin: 0 8px;
      background: rgba(69, 71, 90, 0.4);
      border-radius: 12px;
      padding: 4px;
    }

    #workspaces button {
      padding: 4px 10px;
      margin: 2px;
      background: transparent;
      color: #7f849c;
      border-radius: 8px;
      transition: all 0.3s ease;
      min-width: 30px;
    }

    #workspaces button:hover {
      background: rgba(116, 199, 236, 0.2);
      color: #74c7ec;
    }

    #workspaces button.active {
      background: linear-gradient(45deg, #74c7ec, #89b4fa);
      color: #11111b;
      font-weight: bold;
      box-shadow: 0 2px 8px rgba(116, 199, 236, 0.3);
    }

    #window {
      margin: 0 12px;
      padding: 4px 12px;
      background: rgba(69, 71, 90, 0.4);
      border-radius: 12px;
      color: #cdd6f4;
      font-weight: 400;
    }

    #custom-os {
      background: linear-gradient(45deg, #89b4fa, #cba6f7);
      color: #11111b;
      padding: 6px 12px;
      margin: 4px 0 4px 8px;
      border-radius: 12px;
      font-size: 16px;
      font-weight: bold;
    }

    #custom-separator {
      color: #6c7086;
      background: transparent;
      margin: 0 8px;
      font-weight: bold;
    }

    #clock {
      background: linear-gradient(45deg, #cba6f7, #f5c2e7);
      color: #11111b;
      padding: 6px 16px;
      margin: 4px 8px 4px 4px;
      border-radius: 12px;
      font-weight: bold;
      font-size: 15px;
    }

    #cpu {
      background: linear-gradient(45deg, #a6e3a1, #94e2d5);
      color: #11111b;
      padding: 6px 12px;
      margin: 4px 2px;
      border-radius: 10px;
      font-weight: 600;
    }

    #memory {
      background: linear-gradient(45deg, #fab387, #f9e2af);
      color: #11111b;
      padding: 6px 12px;
      margin: 4px 2px;
      border-radius: 10px;
      font-weight: 600;
    }

    #temperature {
      background: linear-gradient(45deg, #f38ba8, #eba0ac);
      color: #11111b;
      padding: 6px 12px;
      margin: 4px 2px;
      border-radius: 10px;
      font-weight: 600;
    }

    #temperature.critical {
      background: linear-gradient(45deg, #f38ba8, #f38ba8);
      animation: blink 1s ease-in-out infinite alternate;
    }

    #network {
      background: linear-gradient(45deg, #74c7ec, #89b4fa);
      color: #11111b;
      padding: 6px 12px;
      margin: 4px 2px;
      border-radius: 10px;
      font-weight: 600;
    }

    #network.disconnected {
      background: rgba(243, 139, 168, 0.8);
      color: #ffffff;
    }

    #pulseaudio {
      background: linear-gradient(45deg, #f9e2af, #fab387);
      color: #11111b;
      padding: 6px 12px;
      margin: 4px 2px;
      border-radius: 10px;
      font-weight: 600;
    }

    #pulseaudio.muted {
      background: rgba(108, 112, 134, 0.8);
      color: #f4f4f5;
    }

    #bluetooth {
      background: linear-gradient(45deg, #89b4fa, #cba6f7);
      color: #11111b;
      padding: 6px 12px;
      margin: 4px 2px;
      border-radius: 10px;
      font-weight: 600;
    }

    #bluetooth.disabled,
    #bluetooth.off {
      background: rgba(108, 112, 134, 0.8);
      color: #f4f4f5;
    }


    /* Smooth hover animations */
    #cpu:hover, #memory:hover, #temperature:hover,
    #network:hover, #pulseaudio:hover, #clock:hover {
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
      transition: all 0.2s ease;
    }

    @keyframes blink {
      to {
        background-color: #f38ba8;
      }
    }
  '';

  # Ensure waybar package is available
  environment.systemPackages = with pkgs; [
    waybar
  ];
}