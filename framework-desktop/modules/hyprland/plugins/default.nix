# Hyprland plugins configuration
{ config, pkgs, lib, inputs, pkgs-unstable, ... }:

with lib; let
  hypr-plugin-dir = pkgs.symlinkJoin {
    name = "hyprland-plugins";
    paths = with pkgs-unstable.hyprlandPlugins; [
      hy3
      hyprexpo
      hyprfocus
      hyprbars
      hyprspace
    ];
  };
in
{
  # Plugin directory environment variable
  environment.sessionVariables = {
    HYPR_PLUGIN_DIR = "${hypr-plugin-dir}";
  };

  # Plugin loading commands
  environment.etc."hypr/hyprland-plugins.conf".text = ''
    # Load Hyprland plugins
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhy3.so"
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhyprexpo.so"
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhyprfocus.so"
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhyprbars.so"
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhyprspace.so"
  '';
}