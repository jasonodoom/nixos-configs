# Development tools and environment
{ config, pkgs, lib, ... }:

{
  # Development programs
  programs = {
    adb.enable = false;
    direnv.enable = true;
  };

  # Development packages
  environment.systemPackages = with pkgs; [
    # Version control
    git
    git-interactive-rebase-tool
    gh

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