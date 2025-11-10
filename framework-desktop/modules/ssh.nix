{ config, pkgs, lib, ... }:

{
  # SSH server configuration
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

  # Enable SSH agent authentication
  security.pam.sshAgentAuth.enable = true;
  security.pam.services.sudo.sshAgentAuth = false;

  # GPG agent handles SSH (YubiKey support)
  programs.ssh.startAgent = false;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # SSH client configuration
  programs.ssh = {
    enable = true;

    # Global SSH client settings
    extraConfig = ''
      # Global defaults for all hosts
      Host *
        # Protocol and security settings
        Protocol 2
        HashKnownHosts yes
        PasswordAuthentication no
        StrictHostKeyChecking ask
        PubkeyAuthentication yes
        IdentitiesOnly yes
        VisualHostKey yes
        LogLevel INFO

        # Connection multiplexing for performance
        ControlMaster auto
        ControlPath ~/.ssh/controlmasters/%r@%h:%p
        ControlPersist 10m

        # Security hardening
        UseRoaming no
        ServerAliveInterval 60
        ServerAliveCountMax 3

        # Modern cryptographic preferences
        KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
        HostKeyAlgorithms ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,rsa-sha2-512,rsa-sha2-256
        Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
        MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com

        # Default identity files (Ed25519 preferred, then RSA fallback)
        IdentityFile ~/.ssh/id_ed25519
        IdentityFile ~/.ssh/id_rsa

        # Default user
        User jason

      # GitHub configuration with YubiKey
      Host github.com
        HostName github.com
        User git
        PubkeyAuthentication yes
        IdentitiesOnly yes
        IdentityFile ~/.ssh/id_rsa_yubikey.pub

      # GitLab configuration (if needed)
      Host gitlab.com
        HostName gitlab.com
        User git
        PubkeyAuthentication yes
        IdentitiesOnly yes
        IdentityFile ~/.ssh/id_rsa_yubikey
        IdentityFile ~/.ssh/id_ed25519_yubikey
        IdentityAgent SSH_AUTH_SOCK
    '';
  };

  # Ensure SSH control masters directory exists
  systemd.user.services.ssh-controlmasters = {
    description = "Create SSH ControlMaster directory";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/mkdir -p %h/.ssh/controlmasters";
    };
  };

  # SSH client packages
  environment.systemPackages = with pkgs; [
    openssh
  ];

  # Ensure proper SSH agent is running (GPG agent handles SSH with YubiKey support)
  # This is already configured in security.nix with programs.gnupg.agent.enableSSHSupport = true
}