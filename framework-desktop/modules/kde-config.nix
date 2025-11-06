# KDE Plasma 6 Configuration with MacSonoma Theme
{ config, pkgs, lib, ... }:

{
  # Enable KDE Plasma 6
  services.desktopManager.plasma6.enable = true;

  # KDE applications and theme support
  environment.systemPackages = with pkgs; [
    # KDE Applications
    kdePackages.kate          # Text editor
    kdePackages.dolphin       # File manager
    kdePackages.konsole       # Terminal
    kdePackages.spectacle     # Screenshots
    kdePackages.kscreen       # Display management
    kdePackages.systemsettings # System settings

    kdePackages.kactivitymanagerd

    # Additional theming tools
    kdePackages.plasma-browser-integration
    kdePackages.kdeconnect-kde
  ];

  # Configure default KDE theme settings
  environment.etc."xdg/kdeglobals".text = ''
    [General]
    ColorScheme=MacSonomaDark

    [Icons]
    Theme=MacSonoma

    [KDE]
    LookAndFeelPackage=com.github.vinceliuice.MacSonoma-Dark

    [WM]
    activeBackground=59,61,64
    activeBlend=255,255,255
    activeForeground=252,252,252
  '';

  # Plasma desktop configuration for macOS-style layout
  environment.etc."xdg/plasma-org.kde.plasma.desktop-appletsrc".text = ''
    [ActionPlugins][0]
    LeftButton;NoModifier=org.kde.contextmenu
    MidButton;NoModifier=org.kde.paste
    RightButton;NoModifier=org.kde.contextmenu

    [ActionPlugins][1]
    RightButton;NoModifier=org.kde.contextmenu

    [Containments][1]
    activityId=
    formfactor=0
    immutability=1
    lastScreen=0
    location=0
    plugin=org.kde.plasma.folder
    wallpaperplugin=org.kde.image

    [Containments][1][Wallpaper][org.kde.image][General]
    Image=file:///run/current-system/sw/share/wallpapers/MacSonoma/contents/images/3840x2160.png
    SlidePaths=/home/jason/.local/share/wallpapers,/usr/share/wallpapers

    [Containments][2]
    activityId=
    formfactor=2
    immutability=1
    lastScreen=0
    location=3
    plugin=org.kde.panel
    wallpaperplugin=org.kde.image

    [Containments][2][Applets][3]
    immutability=1
    plugin=org.kde.plasma.kickoff

    [Containments][2][Applets][3][Configuration]
    PreloadWeight=100
    popupHeight=514
    popupWidth=651

    [Containments][2][Applets][3][Configuration][General]
    icon=nix-snowflake
    favoriteApps=preferred://filemanager,firefox.desktop,org.kde.konsole.desktop

    [Containments][2][General]
    AppletOrder=3
  '';
}