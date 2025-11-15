# Development tools and environment
{ config, pkgs, lib, ... }:

{
  # Development programs
  programs = {
    adb.enable = false;
    # direnv configuration now in shell.nix
  };

  # VSCode server for remote development
  services.vscode-server = {
    enable = true;
    # Bind to Tailscale interface
  };

  # Caddy reverse proxy for VSCode server with Tailscale HTTPS
  services.caddy = {
    enable = true;
    virtualHosts."perdurabo.ussuri-elevator.ts.net" = {
      extraConfig = ''
        reverse_proxy localhost:8080
        basicauth {
          jason $2b$12$0aVf86wJXtbiJWMQ1rXuNu32atVKWPzrcLoZ4iy96PJkC8S5EywyW
        }
        tls {
          get_certificate tailscale
        }
      '';
    };
  };

  # VSCode server configuration
  services.vscode-server.enable = true;

  # Firewall configuration for VSCode server via Caddy
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 80 443 ];

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