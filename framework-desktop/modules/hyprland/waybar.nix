# Ultimate Modern Waybar Configuration - macOS Sonoma Style
{ config, pkgs, lib, ... }:

{

  # Install waybar but don't enable globally (will be started by Hyprland only)
  # programs.waybar.enable = true;



  # Install required dependencies for waybar modules
  environment.systemPackages = with pkgs; [
    # Waybar itself (for Hyprland only)
    waybar

    # Waybar-specific tools (rofi/wlogout installed by other modules)
    clipse             # Modern clipboard manager
    nwg-displays       # Monitor configuration GUI

    # Waybar-specific packages
    font-awesome           # Font Awesome icons for waybar

    # Network and system utilities for waybar functionality
    networkmanager
    networkmanagerapplet
    pavucontrol
    pwvucontrol  # PipeWire volume control
    htop
    btop
    playerctl  # Media control
    jq         # JSON processing for waybar
    lm_sensors # Temperature monitoring
  ];

  # Waybar configuration - Matte Black Theme
  # https://github.com/tahayvr/matte-black-theme
  environment.etc."xdg/waybar/config".text = builtins.toJSON {
    layer = "top";
    position = "top";
    height = 32;
    spacing = 0;

    modules-left = [
      "hyprland/workspaces"
      "custom/lock"
      "custom/reboot"
      "custom/power"
    ];

    modules-center = [
      "hyprland/window"
    ];

    modules-right = [
      "network"
      "battery"
      "wireplumber"
      "custom/temperature"
      "memory"
      "cpu"
      "clock"
    ];

    # Module configurations

    "hyprland/workspaces" = {
      disable-scroll = false;
      all-outputs = true;
      format = "{icon}";
      on-click = "activate";
      persistent-workspaces = {
        "*" = [1 2 3 4 5 6 7 8 9];
      };
      format-icons = {
        "1" = "<span>  </span>";
        "2" = "<span> 󰅩 </span>";
        "3" = "<span>  </span>";
        "4" = "<span>  </span>";
        "5" = "<span> 󰉋 </span>";
        "6" = "<span>  </span>";
        "7" = "<span>  </span>";
        "8" = "<span>  </span>";
        "default" = "<span>  </span>";
      };
    };

    "hyprland/window" = {
      max-length = 50;
      separate-outputs = false;
    };

    "custom/lock" = {
      format = "<span>  </span>";
      on-click = "hyprlock";
      tooltip = true;
      tooltip-format = "Lock: Super + L";
    };

    "custom/reboot" = {
      format = "<span>  </span>";
      on-click = "systemctl reboot";
      tooltip = true;
      tooltip-format = "Reboot";
    };

    "custom/power" = {
      format = "<span>  </span>";
      on-click = "systemctl poweroff";
      tooltip = true;
      tooltip-format = "Shutdown";
    };

    "custom/temperature" = {
      format = "{}°C";
      exec = "sensors | grep 'Core 0' | awk '{print $3}' | sed 's/+//;s/°C.*//' || echo '0'";
      interval = 10;
      tooltip = false;
    };

    "custom/keybindings" = {
      tooltip = false;
      format = "";
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

# Tray removed - using individual themed modules instead

    idle_inhibitor = {
      format = "{icon}";
      format-icons = {
        activated = "󰅶";
        deactivated = "󰾪";
      };
      tooltip-format-activated = "Idle inhibited - Screen will NOT lock or turn off";
      tooltip-format-deactivated = "Idle enabled - Screen will lock after 1min";
      on-click = "notify-send 'Idle Management' 'Toggled idle inhibitor. Status will update in waybar.'";
    };

    "custom/clipboard" = {
      format = "";
      tooltip = false;
      on-click = "clipse";
    };

    "custom/notifications" = {
      format = "{}";
      tooltip = "Notifications • Click to open history • Right-click to toggle";
      on-click = "bash -c 'if [ $(dunstctl count history) -gt 0 ]; then dunstctl history | rofi -dmenu -i -p \"Notification History\" -lines 10 -width 60; else notify-send \"Notification Center\" \"No notifications in history\"; fi'";
      on-click-right = "dunstctl set-paused toggle && notify-send 'Notifications' \"$(dunstctl is-paused | grep -q 'true' && echo 'Paused' || echo 'Resumed')\"";
      on-click-middle = "dunstctl close-all && notify-send 'Notifications' 'All notifications cleared'";
      exec = "if dunstctl is-paused | grep -q 'false'; then count=$(dunstctl count waiting); if [ $count -gt 0 ]; then echo \"󰂚 $count\"; else echo '󰂚'; fi; else echo '󰂜'; fi";
      interval = 3;
    };

    "custom/screenshare" = {
      format = "{}";
      exec = "if pgrep -f 'screen.*share\\|record\\|obs' >/dev/null; then echo '📺'; else echo ''; fi";
      interval = 3;
      tooltip = "Screen sharing active";
    };

    "custom/microphone" = {
      format = "{}";
      exec = "if pactl list sources | grep -A 10 'Name.*input' | grep -q 'State: RUNNING'; then echo '🎤'; else echo ''; fi";
      interval = 2;
      tooltip = "Microphone in use";
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
      on-click = "pavucontrol";
      on-click-right = "pwvucontrol";
      tooltip-format = "{desc} • Click: pavucontrol • Right-click: pwvucontrol";
      max-volume = 150;
    };

    bluetooth = {
      format = "󰂯 {status}";
      format-connected = "󰂱 {device_alias}";
      format-connected-battery = "󰂱 {device_alias} {device_battery_percentage}%";
      format-disabled = "󰂲 Off";
      tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
      tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
      tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
      tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
      on-click = "blueman-manager";
    };

    network = {
      format-ethernet = "󰱓 {ifname}";
      format-wifi = "{icon} {signalStrength}%";
      format-disconnected = "󰤮";
      format-icons = ["󰤯" "󰤟" "󰤢" "󰤥" "󰤨"];
      tooltip = false;
      on-click = "nm-connection-editor";
      interval = 5;
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

# Power button removed - using wlogout via keybindings instead
  };

  # Matte Black Theme CSS
  environment.etc."xdg/waybar/style.css".text = ''
    * {
      font-family: "JetBrains Mono Nerd Font", "CaskaydiaMono Nerd Font";
      font-weight: normal;
      font-size: 14px;
    }

    #waybar {
      background-color: rgba(0, 0, 0, 0);
      border: none;
      box-shadow: none;
    }

    #workspaces,
    #window {
      background-color: #0e0e0e;
      color: #8a8a8d;
      padding: 4px 8px;
      margin-top: 6px;
      margin-left: 6px;
      margin-right: 6px;
      border-radius: 10px;
      border-width: 0px;
    }

    #clock,
    #custom-power {
      background-color: #0e0e0e;
      color: #8a8a8d;
      margin-top: 6px;
      margin-right: 6px;
      padding: 4px 8px;
      border-radius: 0 10px 10px 0;
      border-width: 0px;
    }

    #network,
    #custom-lock {
      background-color: #0e0e0e;
      color: #8a8a8d;
      margin-top: 6px;
      margin-left: 12px;
      padding: 4px 8px;
      border-radius: 10px 0 0 10px;
      border-width: 0px;
    }

    #custom-reboot,
    #battery,
    #wireplumber,
    #custom-temperature,
    #memory,
    #cpu {
      background-color: #0e0e0e;
      color: #8a8a8d;
      margin-top: 6px;
      padding: 4px 8px;
      border-width: 0px;
    }

    #custom-temperature.critical,
    #wireplumber.muted {
      color: #f38ba8;
    }

  '';

  # GTK theme configuration for modern dark aesthetic
  environment.etc."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Numix-DarkBlue
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=breeze_cursors
    gtk-font-name=Inter 11
    gtk-application-prefer-dark-theme=true
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle=hintslight
    gtk-xft-rgba=rgb
  '';

  environment.etc."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Numix-DarkBlue
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=breeze_cursors
    gtk-font-name=Inter 11
    gtk-application-prefer-dark-theme=true
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle=hintslight
    gtk-xft-rgba=rgb
  '';

  # Ensure GTK themes are applied for all users
  programs.dconf.enable = true;

  # Create user GTK configuration directory and symlinks
  systemd.user.services.gtk-config = {
    description = "Setup GTK configuration";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p $HOME/.config/gtk-3.0 $HOME/.config/gtk-4.0 && ln -sf /etc/gtk-3.0/settings.ini $HOME/.config/gtk-3.0/settings.ini && ln -sf /etc/gtk-4.0/settings.ini $HOME/.config/gtk-4.0/settings.ini'";
    };
  };
}