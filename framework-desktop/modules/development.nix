# Development tools and environment
{ config, pkgs, lib, ... }:

{
  # Development programs
  programs = {
    adb.enable = false;
  };

  # VSCode server for Remote SSH
  services.vscode-server = {
    enable = true;
  };

  # Code-server for browser-based VSCode
  services.code-server = {
    enable = true;
    auth = "none";
    host = "127.0.0.1";
    port = 8080;
  };

  # Install Settings Sync extension for code-server
  systemd.services.code-server.preStart = lib.mkAfter ''
    ${pkgs.code-server}/bin/code-server --install-extension Shan.code-settings-sync || true
  '';

  # Caddy reverse proxy for code-server with Tailscale HTTPS
  services.caddy = {
    enable = true;
    virtualHosts."perdurabo.ussuri-elevator.ts.net" = {
      extraConfig = ''
        reverse_proxy localhost:8080
      '';
    };
  };

  # Firewall configuration for VSCode server via Caddy
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 80 443 8080 ];

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
    npins
  ];

  # Environment variables
  # environment.variables = {
  #   GOROOT = [ "${pkgs.go.out}/share/go" ];
  # };

  # Path additions
  environment.pathsToLink = [ "/libexec" ];
}