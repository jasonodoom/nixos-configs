# Dunst notification daemon configuration
{ config, lib, pkgs, ... }:

{
  # Dunst configuration file
  environment.etc."xdg/dunst/dunstrc".text = ''
    [global]
    monitor = 0
    follow = keyboard
    geometry = "300x5-30+20"
    indicate_hidden = yes
    shrink = no
    transparency = 0
    notification_height = 0
    separator_height = 2
    padding = 8
    horizontal_padding = 8
    frame_width = 3
    frame_color = "#aaaaaa"
    separator_color = frame
    sort = yes
    idle_threshold = 120
    font = Noto Sans 10
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    show_age_threshold = 60
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    max_icon_size = 32
    sticky_history = yes
    history_length = 20
    browser = /run/current-system/sw/bin/firefox
    always_run_script = true
    title = Dunst
    class = Dunst
    startup_notification = false
    verbosity = mesg
    corner_radius = 8
    force_xinerama = false

    [experimental]
    per_monitor_dpi = false

    [shortcuts]
    close = ctrl+space
    close_all = ctrl+shift+space
    history = ctrl+grave
    context = ctrl+shift+period

    [urgency_low]
    background = "#1a1b26"
    foreground = "#c0caf5"
    timeout = 5

    [urgency_normal]
    background = "#1a1b26"
    foreground = "#c0caf5"
    timeout = 10

    [urgency_critical]
    background = "#f7768e"
    foreground = "#1a1b26"
    timeout = 0
  '';

  # Ensure dunst package is available
  environment.systemPackages = with pkgs; [
    dunst
    libnotify  # for notify-send command
  ];
}