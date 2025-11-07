# Rofi application launcher configuration
{ config, pkgs, ... }:

{
  # Create rofi config symlink for user
  systemd.user.services.rofi-config = {
    description = "Rofi config symlink";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p $HOME/.config/rofi && ln -sf /etc/xdg/rofi/config.rasi $HOME/.config/rofi/config.rasi'";
    };
  };
  # Modern rofi configuration with glassmorphism
  environment.etc."xdg/rofi/config.rasi".text = ''
    configuration {
        modi: "drun,run,window";
        lines: 8;
        columns: 4;
        width: 60;
        font: "Inter 14";
        show-icons: true;
        terminal: "kitty";
        drun-display-format: "{icon} {name}";
        location: 0;
        disable-history: false;
        hide-scrollbar: true;
        display-drun: "󰀻 Apps";
        display-run: "󰅬 Run";
        display-window: "󰖯 Windows";
        sidebar-mode: true;
        hover-select: true;
        me-select-entry: "";
        me-accept-entry: "MousePrimary";
    }

    /* Theme starts here - placed after configuration block for rofi 1.7+ */

    * {
        bg-col: rgba(26, 27, 38, 0.85);
        bg-col-light: rgba(36, 40, 59, 0.9);
        border-col: rgba(122, 162, 247, 0.6);
        selected-col: rgba(122, 162, 247, 0.9);
        blue: #7aa2f7;
        fg-col: #c0caf5;
        fg-col2: #9ece6a;
        grey: rgba(86, 95, 137, 0.8);
        width: 40%;
        font: "Inter 14";
    }

    element-text, element-icon, mode-switcher {
        background-color: inherit;
        text-color: inherit;
    }

    window {
        height: 600px;
        border: 2px;
        border-color: @border-col;
        background-color: @bg-col;
        border-radius: 24px;
        backdrop-filter: blur(20px);
        transparency: "real";
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

  # Ensure rofi packages are available
  environment.systemPackages = with pkgs; [
    rofi-wayland
    rofimoji
  ];
}