# System-wide configuration
{ config, pkgs, lib, ... }:

{
  # System version
  system.stateVersion = "25.05";

  # SDDM theme selection
  services.displayManager.sddm.theme-config = "astronaut-hacker";

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      sandbox = true;
      builders-use-substitutes = true;
      substituters = [
        "https://cache.nixos.org/"
        "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Basic nixpkgs configuration
  nixpkgs.config = {
    allowBroken = false;
  };

  # Hardware enablement
  hardware = {
    enableRedistributableFirmware = true;
    # enableAllFirmware = true;  # Disabled to avoid unfree firmware requirement
  };

  # System services
  services = {
    fwupd.enable = true;
    tailscale.enable = true;
    printing.enable = true;
  };

  # Time zone
  time.timeZone = "America/New_York";

  # Hostname
  networking.hostName = "perdurabo";

  # System upgrades
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    flake = "github:jasonodoom/nixos-configs?dir=framework-desktop";
  };

  # Disable suspension and hibernation
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # Logind configuration for desktop
  services.logind.extraConfig = ''
    HandlePowerKey=poweroff
    IdleAction=lock
  '';

  # Power management - minimal for desktop workstation
  powerManagement.enable = false;
}