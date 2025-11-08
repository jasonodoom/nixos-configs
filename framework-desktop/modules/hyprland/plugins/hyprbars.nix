# hyprbars plugin configuration - Window titlebars matching matte-black theme
{ config, pkgs, lib, inputs, ... }:

{
  # hyprbars configuration in hyprland.conf
  environment.etc."hypr/hyprbars.conf".text = ''
    # hyprbars plugin configuration - matches matte-black theme
    plugin {
        hyprbars {
            # general config
            bar_height = 28
            bar_precedence_over_border = true
            bar_part_of_window = true
            bar_color = rgba(0e0e0eff)

            # title config
            col.text = rgba(8a8a8dff)
            bar_text_font = JetBrains Mono Nerd Font
            bar_text_size = 11
            bar_text_align = center

            # button config
            bar_button_padding = 8
            bar_buttons_alignment = right

            # buttons
            hyprbars-button = rgba(f38ba8ff), 12, 󰖭, hyprctl dispatch killactive
            hyprbars-button = rgba(fab387ff), 12, 󰖰, hyprctl dispatch fullscreen 1
            hyprbars-button = rgba(a6e3a1ff), 12, 󰖯, hyprctl dispatch togglefloating
        }
    }
  '';
}