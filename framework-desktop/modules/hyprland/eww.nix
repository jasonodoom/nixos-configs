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

    ;; Modern glassmorphism system info widget
    (defwidget sysinfo []
      (box :class "main-container"
           :orientation "v"
           :spacing 0
        ;; Header section with time
        (box :class "time-section"
             :orientation "v"
             :spacing 4
          (label :class "time" :text time)
          (label :class "date" :text date)
        )

        ;; System stats cards
        (box :class "stats-container"
             :orientation "v"
             :spacing 8
          (box :class "stat-card cpu-card"
               :orientation "v"
               :spacing 2
            (label :class "stat-icon" :text "")
            (label :class "stat-value" :text "''${cpu_usage}%")
            (label :class "stat-label" :text "CPU")
          )

          (box :class "stat-card ram-card"
               :orientation "v"
               :spacing 2
            (label :class "stat-icon" :text "")
            (label :class "stat-value" :text "''${memory_usage}%")
            (label :class "stat-label" :text "RAM")
          )

          (box :class "stat-card workspace-card"
               :orientation "v"
               :spacing 2
            (label :class "stat-icon" :text "")
            (label :class "stat-value" :text "''${workspace}")
            (label :class "stat-label" :text "SPACE")
          )
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

  # Modern Glassmorphism Theme CSS - Tokyo Night Colors
  environment.etc."xdg/eww/eww.css".text = ''
    * {
      all: unset;
      font-family: "SF Pro Display", "Inter", "JetBrains Mono Nerd Font", sans-serif;
    }

    .main-container {
      background: linear-gradient(145deg, rgba(26, 27, 38, 0.85), rgba(36, 40, 59, 0.75));
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border: 1px solid rgba(192, 202, 245, 0.1);
      border-radius: 24px;
      padding: 20px 16px;
      margin: 8px;
      box-shadow:
        0 20px 40px rgba(0, 0, 0, 0.3),
        inset 0 1px 0 rgba(255, 255, 255, 0.1);
    }

    .time-section {
      text-align: center;
      margin-bottom: 16px;
      padding-bottom: 12px;
      border-bottom: 1px solid rgba(65, 72, 104, 0.3);
    }

    .time {
      font-size: 20px;
      font-weight: 700;
      background: linear-gradient(135deg, #7aa2f7, #bb9af7);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 4px;
    }

    .date {
      font-size: 11px;
      color: rgba(187, 154, 247, 0.8);
      font-weight: 500;
      letter-spacing: 0.5px;
      text-transform: uppercase;
    }

    .stats-container {
      margin-top: 8px;
    }

    .stat-card {
      background: linear-gradient(135deg, rgba(122, 162, 247, 0.1), rgba(125, 207, 255, 0.05));
      border: 1px solid rgba(122, 162, 247, 0.2);
      border-radius: 16px;
      padding: 12px 8px;
      text-align: center;
      transition: all 0.3s ease;
      backdrop-filter: blur(10px);
      position: relative;
      overflow: hidden;
    }

    .stat-card::before {
      content: "";
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 1px;
      background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
    }

    .cpu-card {
      border-color: rgba(158, 206, 106, 0.3);
      background: linear-gradient(135deg, rgba(158, 206, 106, 0.15), rgba(158, 206, 106, 0.05));
    }

    .ram-card {
      border-color: rgba(255, 158, 100, 0.3);
      background: linear-gradient(135deg, rgba(255, 158, 100, 0.15), rgba(255, 158, 100, 0.05));
    }

    .workspace-card {
      border-color: rgba(187, 154, 247, 0.3);
      background: linear-gradient(135deg, rgba(187, 154, 247, 0.15), rgba(187, 154, 247, 0.05));
    }

    .stat-icon {
      font-size: 16px;
      color: rgba(192, 202, 245, 0.7);
      margin-bottom: 4px;
    }

    .stat-value {
      font-size: 16px;
      font-weight: 700;
      color: #c0caf5;
      margin-bottom: 2px;
    }

    .stat-label {
      font-size: 8px;
      color: rgba(192, 202, 245, 0.6);
      font-weight: 600;
      letter-spacing: 1px;
      text-transform: uppercase;
    }

    /* Hover effects for interactivity */
    .stat-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
      border-color: rgba(122, 162, 247, 0.4);
    }
  '';
}