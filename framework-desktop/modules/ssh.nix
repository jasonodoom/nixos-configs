{ config, pkgs, lib, ... }:

{
  services.openssh = {
    enable = true;
    ports = [ 666 ];
    settings = {
      X11Forwarding = true;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
      KbdInteractiveAuthentication = true;
    };
    authorizedKeysFiles = [ ".ssh/authorized_keys" ];
    extraConfig = "AllowUsers jason";
  };

  security.pam.sshAgentAuth.enable = true;
  security.pam.services.sudo.sshAgentAuth = false;

  programs.ssh.startAgent = false;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  environment.etc."ssh/ssh_config".text = ''
    Host *
      Protocol 2
      HashKnownHosts yes
      PasswordAuthentication no
      StrictHostKeyChecking ask
      PubkeyAuthentication yes
      IdentitiesOnly yes
      VisualHostKey yes
      LogLevel INFO
      ControlMaster auto
      ControlPath ~/.ssh/controlmasters/%r@%h:%p
      ControlPersist 10m
      UseRoaming no
      ServerAliveInterval 60
      ServerAliveCountMax 3
      KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
      HostKeyAlgorithms ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,rsa-sha2-512,rsa-sha2-256
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
      MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
      IdentityFile ~/.ssh/id_ed25519
      IdentityFile ~/.ssh/id_rsa
      User jason

    Host github.com
      HostName github.com
      User git
      PubkeyAuthentication yes
      IdentitiesOnly yes
      IdentityFile ~/.ssh/id_rsa_yubikey.pub

    Host gitlab.com
      HostName gitlab.com
      User git
      PubkeyAuthentication yes
      IdentitiesOnly yes
      IdentityFile ~/.ssh/id_rsa_yubikey.pub
  '';

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