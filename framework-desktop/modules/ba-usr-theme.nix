# BA_usr inspired theme configuration for Hyprland
# Inspired by: https://gitlab.com/BA_usr/dotfiles-for-hyperland
{ config, pkgs, lib, ... }:

{
  # Hyprpaper configuration for wallpaper management
  environment.etc."xdg/hypr/hyprpaper.conf".text = ''
    preload = /etc/wallpapers/default.png
    wallpaper = ,/etc/wallpapers/default.png
    splash = false
    ipc = on
  '';

  # Enhanced Rofi configuration - BA_usr style
  environment.etc."xdg/rofi/config.rasi".text = ''
    configuration {
      modi: "drun,run,window,ssh,combi";
      font: "JetBrains Mono Nerd Font 12";
      show-icons: true;
      terminal: "kitty";
      drun-display-format: "{icon} {name}";
      location: 0;
      disable-history: false;
      hide-scrollbar: true;
      display-drun: "   Apps ";
      display-run: "   Run ";
      display-window: " 󰕰  Window";
      display-Network: " 󰤨  Network";
      sidebar-mode: true;
    }

    @theme "catppuccin-mocha"
  '';

  # Create Catppuccin Mocha theme for Rofi
  environment.etc."xdg/rofi/catppuccin-mocha.rasi".text = ''
    * {
        bg-col:  #1e1e2e;
        bg-col-light: #1e1e2e;
        border-col: #cba6f7;
        selected-col: #1e1e2e;
        blue: #89b4fa;
        fg-col: #cdd6f4;
        fg-col2: #f38ba8;
        grey: #6c7086;

        width: 600;
        font: "JetBrains Mono Nerd Font 14";
    }

    element-text, element-icon, mode-switcher {
        background-color: inherit;
        text-color:       inherit;
    }

    window {
        height: 360px;
        border: 3px;
        border-color: @border-col;
        background-color: @bg-col;
        border-radius: 15px;
    }

    mainbox {
        background-color: @bg-col;
    }

    inputbar {
        children: [prompt,entry];
        background-color: @bg-col;
        border-radius: 5px;
        padding: 2px;
    }

    prompt {
        background-color: @blue;
        padding: 6px;
        text-color: @bg-col;
        border-radius: 3px;
        margin: 20px 0px 0px 20px;
    }

    textbox-prompt-colon {
        expand: false;
        str: ":";
    }

    entry {
        padding: 6px;
        margin: 20px 0px 0px 10px;
        text-color: @fg-col;
        background-color: @bg-col;
    }

    listview {
        border: 0px 0px 0px;
        padding: 6px 0px 0px;
        margin: 10px 0px 0px 20px;
        columns: 1;
        lines: 5;
        background-color: @bg-col;
    }

    element {
        padding: 5px;
        background-color: @bg-col;
        text-color: @fg-col;
    }

    element-icon {
        size: 25px;
    }

    element selected {
        background-color: @selected-col;
        border: 0px 0px 0px 5px;
        border-color: @blue;
    }

    mode-switcher {
        spacing: 0;
    }

    button {
        padding: 10px;
        background-color: @bg-col-light;
        text-color: @grey;
        vertical-align: 0.5;
        horizontal-align: 0.5;
    }

    button selected {
      background-color: @bg-col;
      text-color: @blue;
    }

    message {
        background-color: @bg-col-light;
        margin: 2px;
        padding: 2px;
        border-radius: 5px;
    }

    textbox {
        padding: 6px;
        margin: 20px 0px 0px 20px;
        text-color: @blue;
        background-color: @bg-col-light;
    }
  '';

  # Create wallpapers directory - users can add their own wallpapers here
  environment.etc."wallpapers/.keep".text = "";

  # Create a default wallpaper using imagemagick
  system.activationScripts.createDefaultWallpaper = ''
    mkdir -p /etc/wallpapers
    if [ ! -f /etc/wallpapers/default.png ]; then
      ${pkgs.imagemagick}/bin/convert -size 3840x2160 xc:"#1e1e2e" /etc/wallpapers/default.png
    fi
  '';

  # System packages for BA_usr theme
  environment.systemPackages = with pkgs; [
    # Wallpaper management
    hyprpaper
    feh

    # Enhanced file management and search
    ranger
    fd
    ripgrep
    fzf

    # Icon themes
    papirus-icon-theme

    # Additional utilities
    imagemagick
    maim
    xclip
  ];

  # XDG settings for proper icon themes
  environment.variables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };

  # Configure home directories
  environment.etc."xdg/user-dirs.defaults".text = ''
    DESKTOP=Desktop
    DOWNLOAD=Downloads
    TEMPLATES=Templates
    PUBLICSHARE=Public
    DOCUMENTS=Documents
    MUSIC=Music
    PICTURES=Pictures
    VIDEOS=Videos
  '';
}