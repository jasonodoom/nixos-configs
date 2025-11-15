# System-wide configuration for Congo server
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
      substituters = [
        "https://cache.nixos.org/"
        "https://odoom-nixos-configs.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "odoom-nixos-configs.cachix.org-1:ySk5iYiHKvbuE1FezCjusvvFR98rkXDLMM6bS8SH3SU="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
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

  # Hardware enablement (headless server)
  hardware = {
    enableRedistributableFirmware = true;
    graphics.enable = false;    # No GPU acceleration needed
  };

  # System services (headless server)
  services = {
    fwupd.enable = true;
    printing.enable = false;    # Server doesn't need printing
    xserver.enable = false;     # No graphics needed
    pipewire.enable = false;    # No audio needed
    # Note: pulseaudio disabled by default on headless systems
  };

  # Explicitly disable desktop programs
  programs = {
    xwayland.enable = false;
  };

  # Console configuration for headless server
  console = {
    keyMap = "us";
    # Use default font (no font setting = uses kernel default, always available in initrd)
  };

  # Time zone
  time.timeZone = "America/New_York";

  # Hostname
  networking.hostName = "congo";

  # Disable suspension and hibernation for server
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # Logind configuration for server
  services.logind.settings.Login = {
    HandlePowerKey = "poweroff";
    IdleAction = "ignore";
  };

  # Power management - disabled for server
  powerManagement.enable = false;

  # Enable NixOS containers support
  boot.enableContainers = true;

  # Essential system packages
  environment.systemPackages = with pkgs; [
    htop
    curl
    wget
    vim
    git
    tree
    jq
    nettools
    iproute2
    iotop
    ncdu
    tmux
    screen
    rsync
    unzip
    lsof
    tcpdump
    tshark
    netcat
    magic-wormhole
    grafana-loki  # Includes logcli for querying logs
    openssl
  ];

  # Server optimizations
  environment.variables = {
    # Optimize for headless operation
    TERM = "xterm-256color";
    # LogCLI configuration
    LOKI_ADDR = "http://localhost:3100";
  };

  # Remove unnecessary default packages
  environment.defaultPackages = with pkgs; [
    # Keep only essential packages
    perl
    rsync
    strace
  ];

  # System upgrades
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    flake = "git+ssh://git@github.com/jasonodoom/nixos-configs.git?dir=lenovo-thinkcentre-m710q&ref=main";
    flags = [ "--no-write-lock-file" ];
  };
}