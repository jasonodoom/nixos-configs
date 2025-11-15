# SSH configuration for Congo server
{ config, pkgs, lib, ... }:

{
  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    settings = {
      X11Forwarding = false;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
      KbdInteractiveAuthentication = false;
      MaxAuthTries = 3;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      LoginGraceTime = 30;
      MaxSessions = 2;
      MaxStartups = "2:30:5";
      Protocol = "2";
      StreamLocalBindUnlink = true;
    };
    authorizedKeysFiles = [ ".ssh/authorized_keys" "/etc/ssh/authorized_keys.d/%u" ];
    extraConfig = ''
      AllowUsers amy
      PermitEmptyPasswords no
      PermitUserEnvironment no
      AllowAgentForwarding yes
      AllowTcpForwarding yes
      GatewayPorts no
      PermitTunnel no
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
      KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
      HostKeyAlgorithms ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,rsa-sha2-512,rsa-sha2-256
      MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
      LogLevel VERBOSE
    '';
  };

  security.pam.sshAgentAuth.enable = true;
  security.pam.services.sudo.sshAgentAuth = lib.mkForce false;

  programs.ssh.startAgent = false;

  # SSH configuration for GitHub deploy key access
  programs.ssh.extraConfig = ''
    # Deploy key for system operations (nixos-rebuild, auto-upgrade, etc.)
    Host github-deploy.com
      HostName github.com
      User git
      IdentityFile /etc/ssh/congo_deploy_key
      IdentitiesOnly yes
      StrictHostKeyChecking yes
  '';

  # Smart card support for YubiKey
  services.pcscd.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
  };

  # SSH client configuration from encrypted agenix secret - disabled for initial deployment
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