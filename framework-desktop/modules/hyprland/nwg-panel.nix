# Complete nwg-shell configuration - Modern macOS-inspired desktop
{ config, pkgs, ... }:

{
  # Install complete nwg-shell suite
  environment.systemPackages = with pkgs; [
    nwg-panel
    nwg-dock-hyprland # macOS-style dock
    nwg-drawer        # Launchpad-style app launcher
    nwg-look          # GTK settings editor
    nwg-displays      # Display management utility
    nwg-menu          # Right-click menu

    # Icon themes for proper category display
    papirus-icon-theme
    adwaita-icon-theme
    gnome-themes-extra
  ];

  # nwg-panel configuration for Hyprland (system-wide)
  environment.etc."nwg-panel/config".text = builtins.toJSON [
    {
      name = "panel-top";
      output = "*";
      layer = "bottom";
      position = "top";
      controls = "right";
      width = "auto";
      height = 32;
      homogeneous = true;
      margin-top = 0;
      margin-bottom = 0;
      padding-horizontal = 0;
      padding-vertical = 0;
      spacing = 0;
      items-padding = 0;
      icons = "light";
      css-name = "panel-top";
      modules-left = ["menu-start" "hyprland-workspaces"];
      modules-center = ["hyprland-taskbar"];
      modules-right = ["tray" "controls" "clock"];
      controls-settings = {
        components = ["volume"];
        commands = {};
        show-values = false;
        interval = 1;
        icon-size = 16;
        hover-opens = false;
        leave-closes = true;
        click-closes = false;
        css-name = "controls-window";
        custom-items = [
          {
            name = "Panel settings";
            icon = "nwg-panel";
            cmd = "nwg-panel-config";
          }
        ];
        menu = {
          name = "Exit";
          icon = "system-shutdown-symbolic";
          items = [
            {
              name = "Lock";
              cmd = "swaylock -f -c 000000";
            }
            {
              name = "Logout";
              cmd = "hyprctl dispatch exit";
            }
            {
              name = "Reboot";
              cmd = "systemctl reboot";
            }
            {
              name = "Shutdown";
              cmd = "systemctl -i poweroff";
            }
          ];
        };
      };
      tray = {
        root-css-name = "tray";
        inner-css-name = "inner-tray";
      };
      hyprland-taskbar = {
        name-max-len = 20;
        image-size = 16;
        workspaces-spacing = 0;
        task-padding = 0;
        show-app-icon = true;
        show-app-name = true;
        show-layout = true;
        workspace-buttons = false;
        all-workspaces = true;
        mark-autotiling = true;
        mark-xwayland = true;
        all-outputs = true;
      };
      hyprland-workspaces = {
        numbers = ["1" "2" "3" "4" "5" "6" "7" "8" "9" "10"];
      };
      clock = {
        format = "%H:%M";
        tooltip-text = "%A, %d %B %Y";
        on-left-click = "";
        on-middle-click = "";
        on-right-click = "";
        on-scroll-up = "";
        on-scroll-down = "";
        css-name = "clock";
        interval = 1;
      };
      menu-start = {
        cmd = "nwg-drawer";
        icon = "view-app-grid-symbolic";
        label = "Apps";
        label-position = "right";
        css-name = "menu-start";
        icon-size = 16;
      };
      exclusive-zone = true;
      sigrt = 64;
      use-sigrt = false;
    }
  ];

  # nwg-panel CSS styling (Tokyo Night theme)
  environment.etc."nwg-panel/style.css".text = ''
    /* Tokyo Night theme for nwg-panel */
    window {
      background-color: rgba(26, 27, 38, 0.95);
      color: #c0caf5;
      border: none;
      font-family: "JetBrains Mono Nerd Font";
      font-size: 14px;
    }

    /* Panel background */
    .panel {
      background-color: rgba(26, 27, 38, 0.95);
      color: #c0caf5;
      border-bottom: 2px solid rgba(122, 162, 247, 0.3);
    }

    /* Workspace buttons */
    .workspace-button {
      background: rgba(69, 71, 90, 0.4);
      border-radius: 8px;
      margin: 2px;
      padding: 4px 10px;
      color: #7f849c;
      transition: all 0.3s ease;
    }

    .workspace-button:hover {
      background: rgba(122, 162, 247, 0.2);
      color: #74c7ec;
    }

    .workspace-button.focused {
      background: linear-gradient(45deg, #74c7ec, #89b4fa);
      color: #11111b;
      font-weight: bold;
      box-shadow: 0 2px 8px rgba(122, 162, 247, 0.3);
    }

    /* Taskbar */
    .task-button {
      background: rgba(69, 71, 90, 0.4);
      border-radius: 8px;
      margin: 2px;
      padding: 4px 8px;
      color: #c0caf5;
      transition: all 0.3s ease;
    }

    .task-button:hover {
      background: rgba(122, 162, 247, 0.2);
      color: #7aa2f7;
    }

    .task-button.focused {
      background: rgba(122, 162, 247, 0.3);
      color: #7aa2f7;
      font-weight: bold;
    }

    /* Controls (audio, brightness) */
    .controls {
      background: linear-gradient(45deg, #fab387, #f9e2af);
      color: #11111b;
      border-radius: 10px;
      margin: 4px 2px;
      padding: 6px 12px;
      font-weight: 600;
    }

    .controls:hover {
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
    }

    /* Playerctl */
    .playerctl {
      background: linear-gradient(45deg, #a6e3a1, #94e2d5);
      color: #11111b;
      border-radius: 10px;
      margin: 4px 2px;
      padding: 6px 12px;
      font-weight: 600;
    }

    /* Clock */
    .clock {
      background: linear-gradient(45deg, #cba6f7, #f5c2e7);
      color: #11111b;
      border-radius: 12px;
      margin: 4px 8px 4px 4px;
      padding: 6px 16px;
      font-weight: bold;
      font-size: 15px;
    }

    /* Menu start button */
    .menu-start {
      background: linear-gradient(45deg, #89b4fa, #cba6f7);
      color: #11111b;
      border-radius: 12px;
      margin: 4px 0 4px 8px;
      padding: 6px 12px;
      font-size: 16px;
      font-weight: bold;
    }

    /* Custom power button */
    .custom-button {
      background: linear-gradient(45deg, #f38ba8, #eba0ac);
      color: #11111b;
      border-radius: 10px;
      margin: 4px 8px 4px 2px;
      padding: 6px 12px;
      font-weight: 600;
    }

    /* Tray */
    .tray {
      background: rgba(69, 71, 90, 0.4);
      border-radius: 12px;
      margin: 4px 4px 4px 8px;
      padding: 6px 10px;
    }

    /* Hover effects */
    .controls:hover, .playerctl:hover, .clock:hover,
    .custom-button:hover, .menu-start:hover {
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
      transition: all 0.2s ease;
    }
  '';

  # nwg-dock-hyprland will use default configuration initially
  # Custom pinned apps can be configured via GUI after first launch

  # nwg-dock-hyprland CSS (macOS-inspired styling)
  environment.etc."nwg-dock-hyprland/style.css".text = ''
    window {
      background-color: rgba(26, 27, 38, 0.85);
      border-radius: 20px;
      border: 1px solid rgba(122, 162, 247, 0.2);
      backdrop-filter: blur(20px);
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    }

    #dock {
      background: rgba(26, 27, 38, 0.85);
      backdrop-filter: blur(20px);
      border-radius: 20px;
      padding: 8px;
      border: 1px solid rgba(122, 162, 247, 0.2);
    }

    button {
      all: unset;
      margin: 4px;
      padding: 8px;
      border-radius: 12px;
      transition: all 0.3s cubic-bezier(0.4, 0.0, 0.2, 1);
      background: transparent;
    }

    button:hover {
      background: rgba(122, 162, 247, 0.15);
      transform: translateY(-4px) scale(1.1);
      box-shadow: 0 8px 25px rgba(122, 162, 247, 0.2);
    }

    button:active {
      transform: translateY(-2px) scale(1.05);
    }

    button image {
      transition: all 0.3s cubic-bezier(0.4, 0.0, 0.2, 1);
    }

    /* Active/focused app indicator */
    button.focused {
      background: rgba(122, 162, 247, 0.25);
      box-shadow: 0 0 0 2px rgba(122, 162, 247, 0.5);
    }

    /* Launcher button special styling */
    button.launcher {
      background: linear-gradient(45deg, #89b4fa, #cba6f7);
      color: #11111b;
    }

    button.launcher:hover {
      background: linear-gradient(45deg, #74c7ec, #89b4fa);
      box-shadow: 0 8px 25px rgba(116, 199, 236, 0.3);
    }
  '';

  # nwg-drawer configuration (Launchpad-style app launcher)
  environment.etc."nwg-drawer/drawer.css".text = ''
    window {
      background-color: rgba(26, 27, 38, 0.95);
      color: #c0caf5;
      border-radius: 20px;
      border: 2px solid rgba(122, 162, 247, 0.3);
      backdrop-filter: blur(20px);
    }

    /* Search box */
    #searchbox {
      background: rgba(36, 40, 59, 0.8);
      color: #c0caf5;
      border: 2px solid rgba(122, 162, 247, 0.3);
      border-radius: 15px;
      padding: 12px 20px;
      margin: 20px;
      font-size: 16px;
      font-family: "JetBrains Mono";
    }

    #searchbox:focus {
      border-color: #7aa2f7;
      box-shadow: 0 0 20px rgba(122, 162, 247, 0.3);
      outline: none;
    }

    /* App grid container */
    #grid {
      padding: 20px;
    }

    /* Individual app buttons */
    button {
      all: unset;
      margin: 8px;
      padding: 16px;
      border-radius: 16px;
      transition: all 0.3s cubic-bezier(0.4, 0.0, 0.2, 1);
      background: rgba(36, 40, 59, 0.6);
      min-width: 100px;
      min-height: 100px;
    }

    button:hover {
      background: rgba(122, 162, 247, 0.15);
      transform: translateY(-2px) scale(1.05);
      box-shadow: 0 8px 25px rgba(122, 162, 247, 0.2);
    }

    button:active {
      transform: scale(0.98);
    }

    /* App icons */
    button image {
      padding-bottom: 8px;
      transition: all 0.3s ease;
    }

    /* App labels */
    button label {
      color: #c0caf5;
      font-family: "JetBrains Mono";
      font-size: 12px;
      font-weight: 500;
    }

    /* Category buttons */
    #category-button {
      background: linear-gradient(45deg, #89b4fa, #cba6f7);
      color: #11111b;
      border-radius: 12px;
      padding: 8px 16px;
      margin: 4px;
      font-weight: bold;
    }

    #category-button:hover {
      background: linear-gradient(45deg, #74c7ec, #89b4fa);
      box-shadow: 0 4px 15px rgba(116, 199, 236, 0.3);
    }

    /* Scrollbars */
    scrollbar {
      background: rgba(69, 71, 90, 0.3);
      border-radius: 10px;
    }

    scrollbar slider {
      background: rgba(122, 162, 247, 0.5);
      border-radius: 10px;
    }

    scrollbar slider:hover {
      background: rgba(122, 162, 247, 0.7);
    }
  '';

  # GTK theme configuration for nwg-shell
  environment.etc."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Adwaita-dark
    gtk-icon-theme-name=Adwaita
    gtk-font-name=JetBrains Mono 11
    gtk-cursor-theme-name=breeze_cursors
    gtk-cursor-theme-size=24
    gtk-toolbar-style=GTK_TOOLBAR_BOTH
    gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
    gtk-button-images=1
    gtk-menu-images=1
    gtk-enable-event-sounds=1
    gtk-enable-input-feedback-sounds=1
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle=hintfull
    gtk-application-prefer-dark-theme=1
  '';
}