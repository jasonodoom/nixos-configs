# System-wide configuration
{ config, pkgs, lib, ... }:

{
  # System version
  system.stateVersion = "25.05";

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      sandbox = true;
      builders-use-substitutes = true;
      trusted-users = [ "root" ];
      # Inline gc trigger: when free space drops below min-free,
      # daemon collects garbage until it reaches max-free. Catches
      # build-time fills (microvm rebuilds, large derivations) that
      # the scheduled timer would miss.
      min-free = 5 * 1024 * 1024 * 1024;
      max-free = 25 * 1024 * 1024 * 1024;
      substituters = [
        "https://cache.nixos.org/"
        "https://vega-cache.dev"
        "https://cache.garnix.io"
        "https://odoom-nixos-configs.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "vega-cache-1:cPagS1g69NQGwlBCyTTeKav/NhlN8a7ixuj2uLOkHrQ="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "odoom-nixos-configs.cachix.org-1:ySk5iYiHKvbuE1FezCjusvvFR98rkXDLMM6bS8SH3SU="
      ];
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };

  # Hourly disk-pressure warning. Catches non-nix fills (user code,
  # build caches under /home) that nix gc cannot help with.
  systemd.services.disk-pressure-warn = {
    serviceConfig.Type = "oneshot";
    script = ''
      used=$(${pkgs.coreutils}/bin/df --output=pcent / | tail -1 | tr -dc '0-9')
      if [ "$used" -ge 90 ]; then
        ${pkgs.systemd}/bin/systemd-cat -t disk-pressure -p warning \
          echo "/ is $used% full"
      fi
    '';
  };
  systemd.timers.disk-pressure-warn = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "hourly"; Persistent = true; };
  };

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages;
    binfmt.emulatedSystems = [ "aarch64-linux" ];
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
    printing.enable = true;
  };

  # Time zone
  time.timeZone = "America/New_York";

  # Hostname
  networking.hostName = "perdurabo";

  # System upgrades
  system.autoUpgrade = {
    enable = true;
    operation = "switch";
    allowReboot = false;
    flake = "git+ssh://git@github-deploy.com/jasonodoom/nixos-configs.git?dir=framework-desktop";
    flags = [ "--no-write-lock-file" ];
  };

  # Disable suspension and hibernation
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # Logind configuration for desktop
  services.logind.settings = {
    Login = {
      IdleAction = "lock";
    };
  };

  # Power management - minimal for desktop workstation
  powerManagement.enable = false;
}
