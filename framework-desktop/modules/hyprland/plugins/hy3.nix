# hy3 plugin configuration - Advanced tiling manager
{ config, pkgs, lib, inputs, ... }:

{
  # hy3 configuration in hyprland.conf
  environment.etc."hypr/hy3.conf".text = ''
    # Change default layout to hy3
    general {
        layout = hy3
    }

    # hy3 plugin configuration
    plugin {
        hy3 {
            # no gaps when only one window in a workspace
            no_gaps_when_only = 1
            # node_collapse_policy = 1
            # group_inset = 10
            # tab_first_window = false

            # you can disable gaps and borders for autotiled windows
            autotile {
                col.group_border = rgba(7aa2f7ff)
                col.group_border_active = rgba(bb9af7ff)
                groupbar_priority = 3
                groupbar_text_color = rgba(ffffffff)
            }
        }
    }
  '';

  # hy3 keybindings
  environment.etc."hypr/hy3-binds.conf".text = ''
    # hy3 plugin keybindings
    bind = SUPER, s, hy3:makegroup, h           # Split horizontally
    bind = SUPER, v, hy3:makegroup, v           # Split vertically
    bind = SUPER, a, hy3:changefocus, raise     # Focus parent container
    bind = SUPER, d, hy3:changefocus, lower     # Focus child container
    bind = SUPER, e, hy3:expand, expand         # Expand focused container
    bind = SUPER, w, hy3:expand, shrink         # Shrink focused container
    bind = SUPER SHIFT, s, hy3:changegroup, h  # Change container to horizontal
    bind = SUPER SHIFT, v, hy3:changegroup, v  # Change container to vertical
    bind = SUPER SHIFT, a, hy3:changegroup, opposite  # Toggle container orientation
  '';
}