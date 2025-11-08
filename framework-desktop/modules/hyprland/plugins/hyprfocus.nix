# hyprfocus plugin configuration - Focus animations
{ config, pkgs, lib, inputs, ... }:

{
  # hyprfocus configuration in hyprland.conf
  environment.etc."hypr/hyprfocus.conf".text = ''
    # hyprfocus animations
    animation = hyprfocusIn, 1, 1.7, default
    animation = hyprfocusOut, 1, 1.7, default
  '';
}