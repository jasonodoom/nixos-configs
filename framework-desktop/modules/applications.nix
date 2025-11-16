# Desktop applications and user packages
{ config, pkgs, lib, ... }:

{
  # System-wide applications
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox

    # Communication
    signal-desktop
    thunderbird
    weechat
    pidgin
    pidgin-otr
    element-desktop
    slack

    # Media and Graphics
    vlc
    audacity
    gimp
    krita
    blender
    inkscape
    evince
    imagemagick
    handbrake
    obs-studio
    cheese
    cider  

    # Productivity and Office
    transmission_4-qt
    shutter
    xournalpp
    libreoffice-qt6
    obsidian

    # AI/ML Tools
    ollama

    # Hardware and Electronics
    arduino
    qFlipper  # Flipper Zero

    # 3D Printing
    cura-appimage  # Using AppImage version to avoid libarcus issues
    prusa-slicer

    # File Management
    nautilus
    gparted
    parted
    udiskie

    # Archive and Text Processing
    pdftk

    # Terminal
    ghostty

    # Security and System Tools
    ragenix
    cyberchef
    tcpdump
    tshark
    wireshark
    netcat
    magic-wormhole
    openssl

    # Screen and Display
    arandr
    maim
    scrot
    xclip  
    xcowsay

    # Spell checking
    aspell
    aspellDicts.en

    # WeeChat extensions
    weechatScripts.weechat-notify-send

    # X11 utilities 
    xorg.xprop

    # Remote access
    remmina

    # Additional applications
    google-chrome
    discord
    dbeaver-bin
    burpsuite
    postman
    appimage-run

    # keybase
    # keybase-gui
  ];

  # Enable some applications that need system-level configuration
  programs.dconf.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Ensure desktop entries and icons are properly linked
  environment.pathsToLink = [
    "/share/applications"
    "/share/icons"
  ];
}