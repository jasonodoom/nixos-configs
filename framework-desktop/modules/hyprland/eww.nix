{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [ eww ];

  environment.etc."xdg/eww/eww.yuck".text = ''
    ;; POLLS
    (defpoll time :interval "1s" "date '+%H:%M'")
    (defpoll date :interval "10s" "date '+%A, %b %d'")

    (defpoll cpu_usage :interval "2s" "grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4)} END {print int(usage)}'")
    (defpoll memory_usage :interval "2s" "free | grep Mem | awk '{printf \"%.0f\", $3/$2 * 100.0}'")

    (defpoll workspace :interval "1s" "hyprctl activeworkspace -j | jq '.id' || echo '1'")

    ;; ANIMATED CPU / RAM BAR WIDGET
    (defwidget stat-bar [val label]
      (box :orientation "v" :class "stat-bar-wrapper"
        (box :class "stat-bar-bg"
          (box :class "stat-bar-fill"
                :style "width: ''${val}%")
        )
        (label :class "stat-bar-label" :text label)
      )
    )

    ;; MAIN PANEL
    (defwidget panel []
      (box :class "panel slide-in"
           :orientation "v"
           :spacing 20

        ;; TIME
        (box :class "time-box fade-in"
             :orientation "v"
          (label :class "time" :text time)
          (label :class "date" :text date)
        )

        ;; CPU + RAM
        (box :class "stats fade-in"
          (stat-bar :val cpu_usage :label "CPU")
          (stat-bar :val memory_usage :label "RAM")
        )

        ;; WORKSPACE
        (box :class "workspace-card fade-in"
          (label :class "workspace-value" :text workspace)
          (label :class "workspace-label" :text "WORKSPACE")
        )
      )
    )

    ;; WINDOW
    (defwindow main
      :monitor 0
      :geometry (geometry :x "14px"
                          :y "50px"
                          :width "90px"
                          :height "440px"
                          :anchor "left center")
      :stacking "fg"
      :windowtype "dock"
      :wm-ignore true
      (panel)
    )
  '';

  environment.etc."xdg/eww/eww.css".text = ''
    * {
      all: unset;
      font-family: "Inter", "Source Sans Pro", "Ubuntu", "JetBrains Mono", sans-serif;
    }

    /* ----- PANEL ----- */
    .panel {
      background: rgba(30, 32, 48, 0.55);
      border-radius: 22px;
      padding: 20px 16px;
      backdrop-filter: blur(18px);
      border: 1px solid rgba(120, 130, 170, 0.35);
      box-shadow:
        0 15px 30px rgba(0,0,0,0.35),
        inset 0 1px 0 rgba(255,255,255,0.1);
      animation: panel-slide-in 0.7s cubic-bezier(0.22, 1, 0.36, 1);
    }

    /* Slide-in animation from the left */
    @keyframes panel-slide-in {
      from { transform: translateX(-25px); opacity: 0; }
      to { transform: translateX(0); opacity: 1; }
    }

    .fade-in {
      animation: fade-in 1.2s ease forwards;
      opacity: 0;
    }

    @keyframes fade-in {
      from { opacity: 0; filter: blur(2px); }
      to { opacity: 1; filter: blur(0); }
    }

    /* ----- TIME ----- */
    .time-box {
      text-align: center;
    }

    .time {
      font-size: 22px;
      font-weight: 700;
      background: linear-gradient(135deg, #7aa2f7, #bb9af7);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .date {
      font-size: 11px;
      color: rgba(187, 154, 247, 0.8);
      margin-top: 4px;
    }

    /* ----- WORKSPACE ----- */
    .workspace-card {
      background: rgba(187,154,247,0.10);
      border: 1px solid rgba(187,154,247,0.25);
      border-radius: 14px;
      padding: 10px 6px;
      text-align: center;
      backdrop-filter: blur(8px);
    }

    .workspace-value {
      font-size: 18px;
      font-weight: 700;
      color: #c0caf5;
      margin-bottom: 2px;
    }

    .workspace-label {
      font-size: 9px;
      color: rgba(192,202,245,0.5);
      letter-spacing: 1px;
      text-transform: uppercase;
    }

    /* ----- STAT BARS ----- */
    .stat-bar-wrapper {
      padding: 4px 0;
    }

    .stat-bar-bg {
      background: rgba(120,130,160,0.15);
      border-radius: 6px;
      width: 100%;
      height: 6px;
      overflow: hidden;
      margin-bottom: 6px;
    }

    .stat-bar-fill {
      background: linear-gradient(90deg, #7aa2f7, #bb9af7);
      height: 100%;
      width: 0%;
      border-radius: 6px;
      transition: width 0.6s cubic-bezier(0.22, 1, 0.36, 1);
    }

    .stat-bar-label {
      font-size: 10px;
      text-align: center;
      color: rgba(192,202,245,0.6);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
  '';
}