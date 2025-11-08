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

    ;; Slim vertical system info widget
    (defwidget sysinfo []
      (box :class "sysinfo"
           :orientation "v"
           :spacing 12
           :halign "center"
        (label :class "time" :text time)
        (box :class "separator")
        (label :class "date" :text date)
        (box :class "separator")
        (box :class "stats" :orientation "v" :spacing 8
          (label :class "cpu" :text "''${cpu_usage}%")
          (label :class "cpu-label" :text "CPU")
          (label :class "ram" :text "''${memory_usage}%")
          (label :class "ram-label" :text "RAM")
          (label :class "workspace" :text "''${workspace}")
          (label :class "workspace-label" :text "WS")
        )
      )
    )

    ;; System info window (left side, slim)
    (defwindow sysinfo
      :monitor 0
      :geometry (geometry :x "10px"
                          :y "50px"
                          :width "80px"
                          :height "400px"
                          :anchor "left center")
      :stacking "fg"
      :windowtype "dock"
      :wm-ignore true
      (sysinfo)
    )
  '';

  # Tokyo Night theme CSS for slim vertical widget
  environment.etc."xdg/eww/eww.css".text = ''
    * {
      all: unset;
      font-family: "JetBrains Mono Nerd Font", monospace;
    }

    .sysinfo {
      background-color: rgba(26, 27, 38, 0.9);
      border-radius: 20px;
      border: 2px solid #414868;
      padding: 12px 8px;
      color: #c0caf5;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
    }

    .separator {
      min-height: 1px;
      background-color: #414868;
      margin: 4px 8px;
    }

    .time {
      font-size: 16px;
      font-weight: bold;
      color: #7aa2f7;
      text-align: center;
    }

    .date {
      font-size: 10px;
      color: #bb9af7;
      text-align: center;
    }

    .stats {
      font-size: 10px;
    }

    .cpu, .ram, .workspace {
      font-size: 14px;
      font-weight: bold;
      color: #7dcfff;
      text-align: center;
      min-height: 20px;
    }

    .cpu-label, .ram-label, .workspace-label {
      font-size: 8px;
      color: #565f89;
      text-align: center;
      margin-bottom: 4px;
    }
  '';
}