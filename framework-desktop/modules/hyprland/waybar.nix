# Ultimate Modern Waybar Configuration - macOS Sonoma Style
{ config, pkgs, lib, ... }:

{
  # Install waybar but don't enable globally (will be started by Hyprland only)
  # programs.waybar.enable = true;

  # Copy Nix logo for waybar drawer icon
  environment.etc."xdg/waybar/nix-logo.png".source = ./icons/nix-logo.png;


  # Install required dependencies for waybar modules
  environment.systemPackages = with pkgs; [
    # Waybar itself (for Hyprland only)
    waybar

    # Application launchers and desktop tools
    rofi-wayland        # Application launcher fallback
    rofimoji           # Emoji picker
    clipse             # Modern clipboard manager
    wl-clipboard       # Wayland clipboard utilities
    nwg-drawer         # Modern application drawer (primary)
    nwg-displays       # Monitor configuration GUI
    wlogout            # Logout menu (for custom/power)

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
      "custom/drawer"
      "hyprland/window"
    ];

    modules-center = [
      "hyprland/workspaces"
    ];

    modules-right = [
      "wireplumber"
      "bluetooth"
      "network"
      "tray"
      "cpu"
      "memory"
      "idle_inhibitor"
      "mpris"
      "custom/clipboard"
      "custom/notifications"
      "privacy"
      "custom/keybindings"
      "clock"
      "custom/power"
    ];

    # Module configurations
    "custom/drawer" = {
      format = "❄️";
      tooltip = false;
      on-click = "pgrep nwg-drawer && pkill nwg-drawer || nwg-drawer -mb 200 -mt 200 -mr 200 -ml 200";
    };

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
      format = "";
      tooltip = false;
      on-click = "dunstctl history-pop";
      on-click-right = "dunstctl set-paused toggle";
      on-click-middle = "dunstctl close-all";
    };

    privacy = {
      icon-spacing = 4;
      icon-size = 18;
      transition-duration = 250;
      modules = [
        {
          type = "screenshare";
          tooltip = true;
          tooltip-icon-size = 24;
        }
        {
          type = "audio-out";
          tooltip = true;
          tooltip-icon-size = 24;
        }
        {
          type = "audio-in";
          tooltip = true;
          tooltip-icon-size = 24;
        }
      ];
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
      on-click-right = "pavucontrol";
      on-click-middle = "pwvucontrol";
      tooltip-format = "{desc} • Click: play/pause • Right-click: pavucontrol • Middle-click: pwvucontrol";
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
      format = "";
      tooltip = false;
      on-click = "wlogout --layer-shell --layout /etc/xdg/wlogout/layout --css /etc/xdg/wlogout/style.css";
      on-click-right = "hyprlock";
    };
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