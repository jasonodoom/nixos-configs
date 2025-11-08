# hyprexpo plugin configuration - Workspace overview
{ config, pkgs, lib, inputs, ... }:

{
  # hyprexpo configuration in hyprland.conf
  environment.etc."hypr/hyprexpo.conf".text = ''
    # hyprexpo plugin configuration
    plugin {
        hyprexpo {
            columns = 3
            gap_size = 8
            bg_col = rgb(0e0e0e)
            workspace_method = center current
            skip_empty = false
            gesture_distance = 300
        }
    }
  '';

  # hyprexpo keybindings
  environment.etc."hypr/hyprexpo-binds.conf".text = ''
    # hyprexpo keybindings
    bind = SUPER, grave, hyprexpo:expo, toggle    # Toggle workspace overview (backtick key)
    bind = SUPER, g, hyprexpo:expo, toggle        # Alternative toggle binding
  '';
}