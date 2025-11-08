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
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code

    # Icon and emoji fonts
    twemoji-color-font # Twitter emoji font
    font-awesome
    material-design-icons

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
}