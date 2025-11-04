# Gaming configuration
{ config, lib, pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
  };

  # Hardware support for gaming controllers
  hardware.steam-hardware.enable = true;
  services.xserver.modules = [ pkgs.xorg.xf86inputjoystick ];

  # Gaming packages
  environment.systemPackages = with pkgs; [
    # Games and game tools
  ];

  # Unfree packages (Steam) are allowed in unfree.nix
}