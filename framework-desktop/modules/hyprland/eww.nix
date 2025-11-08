# Eww Widget System Configuration
{ config, pkgs, lib, ... }:

{
  # Install eww widget system (dependencies already installed by other modules)
  environment.systemPackages = with pkgs; [
    eww               # The widget system
  ];

  # Eww configuration
  environment.etc."xdg/eww/eww.yuck".text = ''
    ;; Desktop-focused eww configuration - Tokyo Night theme
    ;; No battery/laptop features, matches waybar style

    ;; Variables for system info
    (defvar reveal_desktop false)
    (defvar reveal_media false)

    ;; Polls for dynamic data
    (defpoll current_player :interval "2s" "playerctl --player=spotify,mpv,%any metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo 'No media playing'")
    (defpoll player_status :interval "1s" "playerctl --player=spotify,mpv,%any status 2>/dev/null || echo 'Stopped'")
    (defpoll current_workspace :interval "1s" "hyprctl activewindow | grep 'workspace:' | awk '{print $2}' | head -1 || echo '1'")

    ;; Desktop launcher/app drawer
    (defwidget app_launcher []
      (box :class "app-launcher"
           :orientation "v"
           :space-evenly false
           :halign "start"
           :valign "start"
        (button :class "launcher-button"
                :onclick "rofi -show drun"
                :tooltip "Application Launcher"
          "󱄅")  ; Simple app grid icon
        (revealer :transition "slidedown"
                  :reveal reveal_desktop
                  :duration "350ms"
          (box :orientation "v"
               :space-evenly false
            (button :class "desktop-button"
                    :onclick "rofi -show window"
                    :tooltip "Window Switcher"
              "󱂬")  ; Window icon
            (button :class "desktop-button"
                    :onclick "rofi -show run"
                    :tooltip "Run Command"
              "")  ; Terminal icon
            (button :class "desktop-button"
                    :onclick "rofimoji"
                    :tooltip "Emoji Picker"
              "󰞅")  ; Emoji icon
            (button :class "desktop-button"
                    :onclick "thunar"
                    :tooltip "File Manager"
              "󰉋"))) ; Folder icon
      )
    )

    ;; Media player widget
    (defwidget media_player []
      (box :class "media-player"
           :orientation "v"
           :space-evenly false
           :visible {player_status != "Stopped"}
        (button :class "media-toggle"
                :onclick "eww update reveal_media=''${!reveal_media}"
                :tooltip "Toggle Media Controls"
          "♪")
        (revealer :transition "slidedown"
                  :reveal reveal_media
                  :duration "300ms"
          (box :orientation "v"
               :space-evenly false
            (label :class "media-info"
                   :text {current_player}
                   :limit-width 25
                   :tooltip {current_player})
            (box :class "media-controls"
                 :orientation "h"
                 :space-evenly true
              (button :onclick "playerctl previous" "⏮")
              (button :onclick "playerctl play-pause"
                {player_status == "Playing" ? "⏸" : "▶"})
              (button :onclick "playerctl next" "⏭"))))))

    ;; System stats widget for corner
    (defwidget system_stats []
      (box :class "system-stats"
           :orientation "v"
           :space-evenly false
        (box :class "stat-item"
             :tooltip "Current Workspace"
          (label :text "WS: ''${current_workspace}"))
        (box :class "stat-item"
             :tooltip "CPU Usage"
          (label :text "CPU: ''${EWW_CPU.avg}%"))
        (box :class "stat-item"
             :tooltip "Memory Usage"
          (label :text "MEM: ''${EWW_RAM.used_mem_perc}%"))
      )
    )

    ;; Main launcher window
    (defwindow app_launcher
      :monitor 0
      :geometry (geometry :x "20px"
                          :y "20px"
                          :width "60px"
                          :height "200px"
                          :anchor "top left")
      :stacking "fg"
      :reserve (struts :distance "80px" :side "left")
      :windowtype "dock"
      :wm-ignore false
      (app_launcher)
    )

    ;; Media player widget (only shows when playing)
    (defwindow media_player
      :monitor 0
      :geometry (geometry :x "20px"
                          :y "240px"
                          :width "200px"
                          :height "120px"
                          :anchor "top left")
      :stacking "fg"
      :windowtype "dock"
      :wm-ignore true
      (media_player)
    )

    ;; System stats in corner
    (defwindow system_stats
      :monitor 0
      :geometry (geometry :x "20px"
                          :y "20px"
                          :width "120px"
                          :height "100px"
                          :anchor "top right")
      :stacking "fg"
      :windowtype "dock"
      :wm-ignore true
      (system_stats)
    )
  '';

  # Eww CSS styling - Tokyo Night theme
  environment.etc."xdg/eww/eww.scss".text = ''
    * {
      all: unset;
      font-family: "JetBrains Mono Nerd Font";
      font-size: 16px;
    }

    // Tokyo Night color scheme
    $bg: #1a1b26;
    $fg: #c0caf5;
    $blue: #7aa2f7;
    $purple: #bb9af7;
    $cyan: #7dcfff;
    $green: #9ece6a;
    $orange: #ff9e64;
    $red: #f7768e;
    $border: #414868;

    .app-launcher {
      background-color: rgba(26, 27, 38, 0.95);
      border-radius: 16px;
      border: 2px solid $border;
      padding: 8px;
    }

    .launcher-button {
      background-color: rgba(122, 162, 247, 0.2);
      border-radius: 12px;
      padding: 12px;
      margin: 4px;
      color: $blue;
      font-size: 24px;
      font-weight: bold;
      transition: all 0.2s ease;

      &:hover {
        background-color: rgba(122, 162, 247, 0.4);
        transform: scale(1.05);
      }
    }

    .desktop-button {
      background-color: rgba(192, 202, 245, 0.1);
      border-radius: 8px;
      padding: 8px;
      margin: 2px;
      color: $fg;
      font-size: 18px;
      transition: all 0.2s ease;

      &:hover {
        background-color: rgba(192, 202, 245, 0.2);
        color: $cyan;
      }
    }

    .system-stats {
      background-color: rgba(26, 27, 38, 0.9);
      border-radius: 12px;
      border: 1px solid $border;
      padding: 8px;
    }

    .stat-item {
      padding: 4px;
      color: $fg;
      font-size: 12px;

      label {
        color: $green;
        font-weight: 500;
      }
    }

    .media-player {
      background-color: rgba(26, 27, 38, 0.95);
      border-radius: 16px;
      border: 2px solid $border;
      padding: 8px;
    }

    .media-toggle {
      background-color: rgba(158, 206, 106, 0.2);
      border-radius: 12px;
      padding: 8px;
      margin: 4px;
      color: $green;
      font-size: 20px;
      transition: all 0.2s ease;

      &:hover {
        background-color: rgba(158, 206, 106, 0.4);
        transform: scale(1.05);
      }
    }

    .media-info {
      color: $fg;
      font-size: 11px;
      padding: 4px;
      text-align: center;
    }

    .media-controls {
      padding: 4px;

      button {
        background-color: rgba(192, 202, 245, 0.1);
        border-radius: 6px;
        padding: 6px;
        margin: 2px;
        color: $cyan;
        font-size: 14px;
        transition: all 0.2s ease;

        &:hover {
          background-color: rgba(125, 207, 255, 0.3);
          transform: scale(1.1);
        }
      }
    }
  '';

  # Eww startup handled by Hyprland exec-once with --config flag for proper NixOS configuration
}