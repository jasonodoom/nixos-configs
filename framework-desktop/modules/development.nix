# Development tools and environment
{ config, pkgs, lib, ... }:

let
  # Latest code-server from GitHub
  code-server = pkgs.code-server.overrideAttrs (oldAttrs: rec {
    version = "4.105.1";
    src = pkgs.fetchFromGitHub {
      owner = "coder";
      repo = "code-server";
      rev = "v${version}";
      hash = "sha256-75k2Vugv+46oVG/Ppxdn7uWryDR4gzj4uSVFNY6YAQM=";
    };
  });
in
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
    package = code-server;
    auth = "none";  # Tailscale network access provides authentication
    host = "127.0.0.1";
    port = 8080;
  };

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
  ];

  # Environment variables
  # environment.variables = {
  #   GOROOT = [ "${pkgs.go.out}/share/go" ];
  # };

  # Path additions
  environment.pathsToLink = [ "/libexec" ];
}