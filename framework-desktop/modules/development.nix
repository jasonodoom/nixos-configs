# Development tools and environment
{ config, pkgs, lib, ... }:

{
  # Development programs
  programs = {
    adb.enable = false;
    # direnv configuration now in shell.nix
  };

  # Development packages
  environment.systemPackages = with pkgs; [
    # AI assistants
    claude-code

    # Version control (git configuration now in git.nix)
    git-interactive-rebase-tool
    delta

    # Editors
    vim
    nano

    # Build/diff tools
    kdiff3

    # Container tools
    minikube
    kubectl

    # System tools
    tree
    wget
    curl
    rsync
    unzip
    p7zip
    file
    htop
    screen
    tmux
    jq
    fzf  # Fuzzy finder for fish-like autocompletion

    # Network tools
    iftop
    inetutils
    tcpdump
    nettools
    bind
    dnsutils

    # USB and hardware tools
    libusb1
    usbutils
    pciutils
    hwinfo
    lsof

    # Terminal utilities
    bash-completion
    moreutils
    xz

    # Development utilities
    mob
  ];

  # Environment variables
  # environment.variables = {
  #   GOROOT = [ "${pkgs.go.out}/share/go" ];
  # };

  # Path additions
  environment.pathsToLink = [ "/libexec" ];
}