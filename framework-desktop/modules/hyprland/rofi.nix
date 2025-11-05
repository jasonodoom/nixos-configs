# Rofi application launcher configuration
{ config, pkgs, ... }:

{
  # Simple rofi configuration that works with NixOS
  environment.etc."xdg/rofi/config.rasi".text = ''
    configuration {
        modi: "drun,run,window";
        lines: 12;
        columns: 3;
        width: 70;
        font: "Fira Code 16";
        show-icons: true;
        terminal: "kitty";
        drun-display-format: "{icon} {name}";
        location: 0;
        disable-history: false;
        hide-scrollbar: true;
        display-drun: "   Apps ";
        display-run: "   Run ";
        display-window: " 🪟  Window";
        sidebar-mode: true;
    }

    * {
        bg-col:  #1a1b26;
        bg-col-light: #24283b;
        border-col: #7aa2f7;
        selected-col: #7aa2f7;
        blue: #7aa2f7;
        fg-col: #c0caf5;
        fg-col2: #9ece6a;
        grey: #565f89;
        width: 1000;
        font: "Fira Code 16";
    }

    element-text, element-icon, mode-switcher {
        background-color: inherit;
        text-color: inherit;
    }

    window {
        height: 700px;
        border: 3px;
        border-color: @border-col;
        background-color: @bg-col;
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
        columns: 3;
        lines: 12;
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
        text-color: @bg-col;
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
  '';

  # Ensure rofi package is available
  environment.systemPackages = with pkgs; [
    rofi-wayland
  ];
}