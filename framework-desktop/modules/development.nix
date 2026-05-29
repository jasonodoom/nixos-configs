# Development tools and environment
{ config, pkgs, pkgs-unstable, ... }:

{
  # programs.adb was removed in nixpkgs 26.05 — systemd 258 handles
  # uaccess automatically. The previous value here was `enable =
  # false` so this is a no-op rather than a dropped capability;
  # adding `pkgs.android-tools` to systemPackages remains optional.

  # Development packages
  environment.systemPackages = with pkgs; [
    # AI assistants run in sandboxed microvms (see modules/ai-microvms.nix),
    # reached from the host via bash aliases in modules/bash/aliases.nix.

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
    nixpkgs-review
    pkgs-unstable.wrangler
  ];

  # Environment variables
  # environment.variables = {
  #   GOROOT = [ "${pkgs.go.out}/share/go" ];
  # };

  # Path additions
  environment.pathsToLink = [ "/libexec" ];
}
