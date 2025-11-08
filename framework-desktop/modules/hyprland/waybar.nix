# Ultimate Modern Waybar Configuration - macOS Sonoma Style
{ config, pkgs, lib, ... }:

{
  imports = [
    ./eww.nix
  ];

  # Install waybar but don't enable globally (will be started by Hyprland only)
  # programs.waybar.enable = true;

# Removed nix logo - replaced with eww


  # Install required dependencies for waybar modules
  environment.systemPackages = with pkgs; [
    # Waybar itself (for Hyprland only)
    waybar

    # Waybar-specific tools (rofi/eww/wlogout installed by other modules)
    clipse             # Modern clipboard manager
    nwg-displays       # Monitor configuration GUI

    # Icon themes for comprehensive application coverage
    adwaita-icon-theme      # GNOME default icons
    hicolor-icon-theme      # Fallback icon theme
    papirus-icon-theme      # Modern colorful icons
    tela-icon-theme         # Flat modern icons
    numix-icon-theme        # Popular flat icons
    kdePackages.breeze-icons  # KDE icons for compatibility
    gnome-themes-extra  # Additional GNOME icons
    font-awesome           # Font Awesome icons for waybar

    # GTK themes for modern dark aesthetic
    arc-theme              # Modern flat theme
    numix-gtk-theme        # Popular dark theme
    nordic                 # Dark Nordic theme (matches Tokyo Night)

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
      "hyprland/window"
    ];

    modules-center = [
      "hyprland/workspaces"
    ];

    modules-right = [
      "wireplumber"
      "bluetooth"
      "network"
      "cpu"
      "memory"
      "idle_inhibitor"
      "mpris"
      "custom/clipboard"
      "custom/screenshare"
      "custom/microphone"
      "custom/notifications"
      "custom/keybindings"
      "clock"
    ];

    # Module configurations removed drawer - using eww instead

    "hyprland/workspaces" = {
      format = "{icon}";
      format-icons = {
        default = "󰧞";
        active = "󰮯";
        urgent = "󰀧";
      };
      on-scroll-up = "hyprctl dispatch workspace e+1";
      on-scroll-down = "hyprctl dispatch workspace e-1";
      show-special = false;
      persistent-workspaces = {
        "1" = [];
        "2" = [];
        "3" = [];
        "4" = [];
        "5" = [];
      };
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

  # ZaneyOS ddubs Style - Modern rounded rectangles with dynamic colors
  # https://gitlab.com/Zaney/zaneyos/
  # Uses a more balanced color scheme instead of heavy red theme
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
      color: #0f0f0f;
      background: #565f89;
      margin: 4px 4px;
      padding: 5px 5px;
      border-radius: 16px;
    }

    #workspaces button {
      font-weight: bold;
      padding: 0px 5px;
      margin: 0px 3px;
      border-radius: 16px;
      color: #0f0f0f;
      background: linear-gradient(45deg, #7dcfff, #bb9af7);
      opacity: 0.5;
      transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
    }

    #workspaces button.active {
      font-weight: bold;
      padding: 0px 5px;
      margin: 0px 3px;
      border-radius: 16px;
      color: #0f0f0f;
      background: linear-gradient(45deg, #7dcfff, #bb9af7);
      transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
      opacity: 1.0;
      min-width: 40px;
    }

    #workspaces button:hover {
      font-weight: bold;
      border-radius: 16px;
      color: #0f0f0f;
      background: linear-gradient(45deg, #7dcfff, #bb9af7);
      opacity: 0.8;
      transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
    }

    tooltip {
      background: #1a1b26;
      border: 1px solid #7dcfff;
      border-radius: 12px;
    }

    tooltip label {
      color: #7dcfff;
    }

    #window, #wireplumber, #cpu, #memory {
      font-weight: bold;
      margin: 4px 7px 4px 0px;
      padding: 0px 18px;
      background: #1a1b26;
      color: #7dcfff;
      border-radius: 8px 8px 8px 8px;
    }

    #network {
      font-weight: bold;
      margin: 4px 0px 4px 7px;
      padding: 0px 18px;
      background: #1a1b26;
      color: #7dcfff;
      border-radius: 8px 8px 8px 8px;
    }

    #idle_inhibitor {
      font-weight: bold;
      margin: 4px 7px 4px 0px;
      padding: 0px 18px;
      background: #1a1b26;
      color: #7dcfff;
      border-radius: 8px 8px 8px 8px;
      font-size: 28px;
    }

    #custom-drawer {
      background-color: #565f89;
      color: #9ece6a;
      font-size: 20px;
      margin: 4px 7px 4px 0px;
      padding: 0px 12px;
      border-radius: 16px;
      min-width: 32px;
    }

    #custom-logo {
      color: #9ece6a;
      background: #565f89;
      font-size: 22px;
      margin: 0px;
      padding: 0px 5px 0px 5px;
      border-radius: 16px 16px 16px 16px;
    }

    #bluetooth {
      font-size: 20px;
      background: #1a1b26;
      color: #7dcfff;
      margin: 4px 7px 4px 0px;
      border-radius: 8px 8px 8px 8px;
      padding: 0px 18px;
    }

    #custom-keybindings, #mpris, #tray, #custom-power {
      font-size: 20px;
      background: #1a1b26;
      color: #7dcfff;
      margin: 4px 7px 4px 0px;
      border-radius: 8px 8px 8px 8px;
      padding: 0px 18px;
    }

    #custom-notifications {
      font-size: 20px;
      background: #1a1b26;
      color: #7dcfff;
      margin: 4px 12px 4px 0px;
      border-radius: 8px 8px 8px 8px;
      padding: 0px 18px;
      transition: all 0.3s ease;
    }

    #custom-notifications.disabled {
      color: #565f89;
      opacity: 0.6;
    }

    #custom-screenshare, #custom-microphone {
      font-size: 18px;
      background: #1a1b26;
      color: #f7768e;
      margin: 4px 7px 4px 0px;
      border-radius: 8px 8px 8px 8px;
      padding: 0px 12px;
    }

    #clock {
      font-weight: bold;
      font-size: 16px;
      color: #0D0E15;
      background: linear-gradient(90deg, #9ece6a, #565f89);
      margin: 0px;
      padding: 0px 5px 0px 5px;
      border-radius: 16px 16px 16px 16px;
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