# Simplified Eww Widget System Configuration - Tokyo Night Theme
{ config, pkgs, lib, ... }:

{
  # Install eww widget system
  environment.systemPackages = with pkgs; [
    eww               # The widget system
  ];

  # Simple, reliable eww configuration
  environment.etc."xdg/eww/eww.yuck".text = ''
    ;; Simple Tokyo Night themed widgets

    ;; System polling variables
    (defpoll time :interval "1s" "date '+%H:%M'")
    (defpoll date :interval "10s" "date '+%A, %b %d'")
    (defpoll cpu_usage :interval "3s" "grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4)} END {print int(usage)}'")
    (defpoll memory_usage :interval "3s" "free | grep Mem | awk '{printf \"%.0f\", $3/$2 * 100.0}'")
    (defpoll workspace :interval "1s" "hyprctl activewindow | grep 'workspace:' | awk '{print $2}' || echo '1'")

    ;; Simple system info widget
    (defwidget sysinfo []
      (box :class "sysinfo"
           :orientation "v"
           :spacing 8
        (label :class "time" :text time)
        (label :class "date" :text date)
        (box :class "stats" :orientation "v" :spacing 4
          (label :class "cpu" :text "CPU: ''${cpu_usage}%")
          (label :class "ram" :text "RAM: ''${memory_usage}%")
          (label :class "workspace" :text "WS: ''${workspace}")
        )
      )
    )

    ;; System info window (top-right corner)
    (defwindow sysinfo
      :monitor 0
      :geometry (geometry :x "10px"
                          :y "10px"
                          :width "200px"
                          :height "150px"
                          :anchor "top right")
      :stacking "fg"
      :windowtype "dock"
      :wm-ignore true
      (sysinfo)
    )
  '';

  # Simple CSS styling - Tokyo Night theme
  environment.etc."xdg/eww/eww.css".text = ''
    * {
      all: unset;
      font-family: "JetBrains Mono Nerd Font";
    }

    .sysinfo {
      background-color: rgba(26, 27, 38, 0.95);
      border-radius: 16px;
      border: 1px solid #414868;
      padding: 16px;
      color: #c0caf5;
    }

    .time {
      font-size: 24px;
      font-weight: bold;
      color: #7aa2f7;
      text-align: center;
      margin-bottom: 8px;
    }

    .date {
      font-size: 14px;
      color: #bb9af7;
      text-align: center;
      margin-bottom: 12px;
    }

    .stats {
      font-size: 12px;
    }

    .cpu, .ram, .workspace {
      padding: 2px 0;
      color: #9ece6a;
    }
  '';
}