# Hyprland plugins configuration
{ config, pkgs, lib, inputs, ... }:

with lib; let
  hyprPluginPkgs = inputs.hyprland-plugins.packages.${pkgs.system};
  hy3Pkg = inputs.hy3.packages.${pkgs.system};
  hyprDarkWindowPkg = inputs.hypr-darkwindow.packages.${pkgs.system};

  hypr-plugin-dir = pkgs.symlinkJoin {
    name = "hyprland-plugins";
    paths = with hyprPluginPkgs; [
      hyprexpo
      hyprfocus
      hyprbars
    ] ++ [
      hy3Pkg.hy3
      pkgs.hyprlandPlugins.hyprspace
      hyprDarkWindowPkg.Hypr-DarkWindow
    ];
  };
in
{
  imports = [
    ./hy3.nix
    ./hyprfocus.nix
    ./hyprbars.nix
    ./hyprexpo.nix
    ./hyprspace.nix
    ./darkwindow.nix
  ];

  # Plugin directory environment variable
  environment.sessionVariables = {
    HYPR_PLUGIN_DIR = "${hypr-plugin-dir}";
  };

  # Plugin loading commands
  environment.etc."hypr/hyprland-plugins.conf".text = ''
    # Load all Hyprland plugins
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhy3.so"
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhyprexpo.so"
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhyprfocus.so"
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhyprbars.so"
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libHyprspace.so"
    exec-once = hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libHypr-DarkWindow.so"
  '';
}