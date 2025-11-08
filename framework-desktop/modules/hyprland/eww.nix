# eww.nix
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [ eww ];

  # Create eww config in user directory instead of symlink
  systemd.user.services.eww-config-setup = {
    description = "Setup eww configuration in user directory";
    wantedBy = [ "graphical-session.target" ];
    before = [ "eww.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p $HOME/.config/eww && cp -r /etc/xdg/eww/* $HOME/.config/eww/ 2>/dev/null || true'";
    };
  };

  # --- EWW YUCK ---
  environment.etc."xdg/eww/eww.yuck".text = ''
    ;; ---------- Polls ----------
    (defpoll time :interval "1s" "date '+%H:%M'")
    (defpoll date :interval "10s" "date '+%a · %b %d'")
    (defpoll cpu_usage :interval "2s" "grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4)} END {print int(usage)}'")
    (defpoll memory_usage :interval "3s" "free | awk '/Mem:/ {printf \"%d\", ($3/$2)*100}'")

    ;; hyprland workspace id (fallback to 1)
    (defpoll workspace :interval "1s" "hyprctl activewindow 2>/dev/null | awk '/workspace:/ {print $2}' | head -n1 | sed 's/[^0-9]//g; s/^$/1/'")

    ;; network up/down in kB/s (simple cached diff via /tmp)
    (defpoll net_up :interval \"1s\" \"\
      IF=$(ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if(\\$i==\"dev\") print \\$(i+1)}' | head -n1); \
      [ -z \\\"$IF\\\" ] && echo 0 && exit; \
      R=/sys/class/net/$IF/statistics/tx_bytes; \
      P=/tmp/eww_tx_prev; C=$(cat $R); \
      [ -f $P ] && DIFF=$((C-$(cat $P))) || DIFF=0; echo $((DIFF/1024)); echo $C > $P\")

    (defpoll net_down :interval \"1s\" \"\
      IF=$(ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if(\\$i==\"dev\") print \\$(i+1)}' | head -n1); \
      [ -z \\\"$IF\\\" ] && echo 0 && exit; \
      R=/sys/class/net/$IF/statistics/rx_bytes; \
      P=/tmp/eww_rx_prev; C=$(cat $R); \
      [ -f $P ] && DIFF=$((C-$(cat $P))) || DIFF=0; echo $((DIFF/1024)); echo $C > $P\")

    ;; ---------- Reusable widgets ----------
    (defwidget statbar [label value]
      (box :class "stat"
           :orientation "v"
           :spacing 6
        (box :class "stat-top"
             :space-evenly false
             :halign "fill"
             (label :class "stat-label" :text label)
             (label :class "stat-val" :text (format \"%s%%\" value)))
        (box :class "bar-bg"
          (box :class "bar-fill"
               :style (format \"width: %s%%;\" value)))))

    (defwidget pill [title main]
      (box :class "pill"
        (label :class "pill-title" :text title)
        (label :class "pill-main" :text main)))

    ;; ---------- The long panel ----------
    (defwidget panel []
      (box :class "panel fade-in"
           :space-evenly false
           :spacing 18
           ;; Left cluster: time & date
           (box :class "cluster"
                :orientation "v"
                :spacing 2
                (label :class "time" :text time)
                (label :class "date" :text date))
           ;; Middle cluster: animated stat bars
           (box :class "cluster wide"
                :spacing 16
                :halign "fill"
                :hexpand true
                (statbar :label "CPU" :value cpu_usage)
                (statbar :label "RAM" :value memory_usage))
           ;; Right cluster: workspace & net
           (box :class "cluster right"
                :spacing 12
                (pill :title "WS" :main workspace)
                (box :class "net"
                  (label :class "net-chip" :text (format \"↓ %s kB/s\" net_down))
                  (label :class "net-chip" :text (format \"↑ %s kB/s\" net_up))))))

    ;; ---------- Window ----------
    (defwindow bar
      :monitor 0
      :stacking "fg"
      :wm-ignore true
      :windowtype "dock"
      :geometry (geometry
                  :x "24px" :y "18px"
                  :width "820px" :height "84px"
                  :anchor "top left")
      (panel))
  '';

  # --- EWW CSS (Tokyo-Night; keep your installed fonts) ---
  environment.etc."xdg/eww/eww.css".text = ''
    * {
      all: unset;
      font-family: "Inter", "Source Sans Pro", "Ubuntu", "JetBrains Mono", sans-serif;
    }

    /* ---------- Keyframes ---------- */
    @keyframes fade-in {
      from { opacity: 0; transform: translateY(-8px); filter: blur(3px); }
      to   { opacity: 1; transform: translateY(0);     filter: blur(0); }
    }
    @keyframes shimmer {
      from { background-position: 0% 50%; }
      to   { background-position: 100% 50%; }
    }
    @keyframes glow {
      0%   { box-shadow: 0 0 0 rgba(122,162,247,0.0); }
      50%  { box-shadow: 0 0 22px rgba(122,162,247,0.20); }
      100% { box-shadow: 0 0 0 rgba(122,162,247,0.0); }
    }

    /* ---------- Panel ---------- */
    .panel {
      background: linear-gradient(145deg, rgba(26,27,38,0.85), rgba(36,40,59,0.80));
      border: 1px solid rgba(120,130,170,0.35);
      border-radius: 22px;
      padding: 18px 20px;
      box-shadow:
        0 20px 42px rgba(0,0,0,0.38),
        inset 0 1px 0 rgba(255,255,255,0.08);
      animation: fade-in 0.7s cubic-bezier(0.22,1,0.36,1);
    }
    .fade-in { opacity: 1; }

    .cluster { align-items: center; }
    .cluster.wide { min-width: 420px; }
    .cluster.right { }

    /* ---------- Time & Date ---------- */
    .time {
      font-size: 28px;
      font-weight: 800;
      line-height: 1.0;
      background: linear-gradient(135deg, #7aa2f7, #bb9af7);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      letter-spacing: 0.5px;
      margin-bottom: 2px;
      text-shadow: 0 0 16px rgba(122,162,247,0.25);
    }
    .date {
      font-size: 12px;
      color: rgba(187,154,247,0.85);
      letter-spacing: 0.6px;
    }

    /* ---------- Stat bars ---------- */
    .stat { min-width: 200px; }

    .stat-label {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: rgba(192,202,245,0.70);
    }
    .stat-val {
      font-size: 12px;
      font-weight: 800;
      color: #c0caf5;
    }

    .bar-bg {
      width: 100%;
      height: 8px;
      background: rgba(120,130,160,0.18);
      border: 1px solid rgba(120,130,170,0.28);
      border-radius: 8px;
      overflow: hidden;
      position: relative;
    }
    .bar-bg::before {
      content: "";
      position: absolute; inset: 0 0 auto 0;
      height: 1px;
      background: linear-gradient(90deg, transparent, rgba(255,255,255,0.25), transparent);
    }
    .bar-fill {
      height: 100%;
      width: 0%;
      border-radius: 8px;
      background: linear-gradient(90deg, #7aa2f7, #bb9af7, #7dcfff);
      background-size: 200% 100%;
      animation: shimmer 2.2s linear infinite;
      transition: width 0.6s cubic-bezier(0.22,1,0.36,1);
      filter: drop-shadow(0 0 8px rgba(122,162,247,0.25));
    }

    /* ---------- Pills & Net chips ---------- */
    .pill {
      background: linear-gradient(135deg, rgba(187,154,247,0.12), rgba(125,207,255,0.08));
      border: 1px solid rgba(187,154,247,0.30);
      border-radius: 14px;
      padding: 10px 12px;
      gap: 8px;
      align-items: center;
      transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
    }
    .pill:hover {
      transform: translateY(-1px);
      border-color: rgba(122,162,247,0.45);
      box-shadow: 0 10px 22px rgba(0,0,0,0.25);
    }
    .pill-title {
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: rgba(192,202,245,0.7);
      margin-right: 6px;
    }
    .pill-main {
      font-size: 14px;
      font-weight: 800;
      color: #c0caf5;
    }

    .net {
      display: flex; gap: 8px; align-items: center;
    }
    .net-chip {
      font-size: 11px;
      font-weight: 700;
      color: #c0caf5;
      padding: 8px 10px;
      border-radius: 12px;
      background: rgba(122,162,247,0.12);
      border: 1px solid rgba(122,162,247,0.30);
      animation: glow 3.6s ease-in-out infinite;
    }
  '';
}