{ config, pkgs, lib, ... }:

{
  services.openssh = {
    enable = true;
    ports = [ 6666 ];
    settings = {
      X11Forwarding = false;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
    authorizedKeysFiles = [ ".ssh/authorized_keys" ];
    extraConfig = ''
      AllowUsers jason@192.168.1.* jason@10.8.* jason@100.* jason@172.16.200.*
      # Entertainment VLAN
      DenyUsers *@10.6.6.*
    '';
  };

  security.pam.sshAgentAuth.enable = true;
  security.pam.services.sudo.sshAgentAuth = false;

  # Initrd SSH and Tailscale remote unlock moved to luks.nix

  programs.ssh.startAgent = false;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  # SSH client configuration from encrypted agenix secret
  # age.secrets.ssh-config = {
  #   file = ../secrets/ssh-config.age;
  #   mode = "0644";
  # };

  # environment.etc."ssh/ssh_config".source = config.age.secrets.ssh-config.path;

  systemd.user.services.ssh-controlmasters = {
    description = "Create SSH ControlMaster directory";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/mkdir -p %h/.ssh/controlmasters";
    };
  };

  environment.systemPackages = with pkgs; [
    openssh
  ];
}