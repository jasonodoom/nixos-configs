{ config, pkgs, lib, ... }:

{
  # Kitty terminal configuration
  environment.etc."xdg/kitty/kitty.conf".text = ''
    font_family Fira Code
    font_size 12
    background_opacity 0.9
    window_padding_width 8

    # Dark theme colors (Tokyo Night)
    foreground #c0caf5
    background #1a1b26
    selection_foreground #c0caf5
    selection_background #33467c

    # Cursor colors
    cursor #c0caf5
    cursor_text_color #1a1b26

    # URL underline color when hovering with mouse
    url_color #73daca

    # Kitty window border colors
    active_border_color #7aa2f7
    inactive_border_color #292e42
    bell_border_color #e0af68

    # OS Window titlebar colors
    wayland_titlebar_color system
    macos_titlebar_color system

    # Tab bar colors
    active_tab_foreground #1f2335
    active_tab_background #7aa2f7
    inactive_tab_foreground #545c7e
    inactive_tab_background #292e42
    tab_bar_background #1d202f

    # Colors for marks (marked text in the terminal)
    mark1_foreground #1a1b26
    mark1_background #73daca
    mark2_foreground #1a1b26
    mark2_background #7dcfff
    mark3_foreground #1a1b26
    mark3_background #7aa2f7

    # The 16 terminal colors
    # black
    color0 #15161e
    color8 #414868

    # red
    color1 #f7768e
    color9 #f7768e

    # green
    color2 #9ece6a
    color10 #9ece6a

    # yellow
    color3 #e0af68
    color11 #e0af68

    # blue
    color4 #7aa2f7
    color12 #7aa2f7

    # magenta
    color5 #bb9af7
    color13 #bb9af7

    # cyan
    color6 #7dcfff
    color14 #7dcfff

    # white
    color7 #a9b1d6
    color15 #c0caf5
  '';
}