# Rofi application launcher configuration
{ config, pkgs, ... }:

{
  # Rofi configuration
  environment.etc."xdg/rofi/config.rasi".text = ''
    configuration {
        modi: "run,drun,window";
        lines: 5;
        font: "Fira Code 10";
        show-icons: true;
        terminal: "kitty";
        drun-display-format: "{icon} {name}";
        location: 0;
        disable-history: false;
        hide-scrollbar: true;
        display-drun: "   Apps ";
        display-run: "   Run ";
        display-window: " 﩯  Window";
        display-Network: " 󰤨  Network";
        sidebar-mode: true;
    }

    @theme "/etc/xdg/rofi/themes/style.rasi"
  '';

  # Rofi theme configuration (Tokyo Night inspired)
  environment.etc."xdg/rofi/themes/style.rasi".text = ''
    * {
        bg-col:  #1a1b26;
        bg-col-light: #24283b;
        border-col: #7aa2f7;
        selected-col: #7aa2f7;
        blue: #7aa2f7;
        fg-col: #c0caf5;
        fg-col2: #9ece6a;
        grey: #565f89;

        width: 600;
        font: "Fira Code 14";
    }

    element-text, element-icon , mode-switcher {
        background-color: inherit;
        text-color: inherit;
    }

    window {
        height: 360px;
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
        columns: 2;
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

  # Ensure rofi package is available
  environment.systemPackages = with pkgs; [
    rofi-wayland
  ];
}