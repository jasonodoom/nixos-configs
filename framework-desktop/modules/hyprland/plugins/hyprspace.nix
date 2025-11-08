# hyprspace plugin configuration - Alternative workspace overview
{ config, pkgs, lib, inputs, ... }:

{
  # hyprspace keybindings
  environment.etc."hypr/hyprspace-binds.conf".text = ''
    # hyprspace keybindings
    bind = SUPER ALT, grave, overview:toggle    # Alternative workspace overview
    bind = SUPER ALT, g, overview:toggle        # Alternative toggle binding
  '';
}