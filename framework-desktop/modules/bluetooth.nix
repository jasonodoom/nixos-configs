# Bluetooth configuration
{ config, pkgs, lib, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  # Bluetooth manager
  services.blueman.enable = true;

  # Make sure bluetooth works with audio
  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
  ];
}