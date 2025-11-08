# Font configuration for Framework Desktop
{ config, pkgs, ... }:

{
  # Font packages
  fonts.packages = with pkgs; [
    # System fonts
    noto-fonts
    noto-fonts-emoji
    liberation_ttf
    dejavu_fonts
    open-sans
    roboto

    # Modern UI fonts
    inter  # Modern sans-serif for ultimate theme
    source-sans-pro  # Similar to SF Pro
    ubuntu_font_family  # Good fallback for system UI fonts

    # Development fonts
    fira-code
    fira-code-symbols
    jetbrains-mono

    # Nerd Fonts for proper icon rendering
    nerd-fonts.jetbrains-mono
    nerd-fonts.caskaydia-mono
    nerd-fonts.victor-mono
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.noto
    nerd-fonts.hack
    nerd-fonts.ubuntu
    nerd-fonts.symbols-only

    # Icon and emoji fonts
    twemoji-color-font # Twitter emoji font
    font-awesome
    material-design-icons
    material-symbols   # Additional Google icons

    # Legacy fonts
    dina-font
    proggyfonts
  ];

  # Font configuration
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Inter" "Noto Sans" ];
      monospace = [ "JetBrains Mono Nerd Font" "Fira Code" ];
      emoji = [ "Twemoji" "Noto Color Emoji" ];
    };
  };

  # Ensure font cache is rebuilt on changes (NixOS does this automatically, but being explicit)
  system.activationScripts.fonts-cache = {
    text = "${pkgs.fontconfig}/bin/fc-cache -r";
    deps = [ ];
  };
}