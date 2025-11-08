# Hypr-DarkWindow plugin configuration - Window effects
{ config, pkgs, lib, inputs, ... }:

{
  # darkwindow configuration in hyprland.conf
  environment.etc."hypr/darkwindow.conf".text = ''
    # Hypr-DarkWindow plugin configuration
    plugin:darkwindow:load_shaders = all    # Load all available shaders (invert, tint, etc.)
  '';

  # Optional keybindings for darkwindow effects (can be customized)
  environment.etc."hypr/darkwindow-binds.conf".text = ''
    # darkwindow keybindings (examples - customize as needed)
    # bind = SUPER SHIFT, i, darkwindow:invert     # Invert window colors
    # bind = SUPER SHIFT, t, darkwindow:tint       # Tint window
  '';
}