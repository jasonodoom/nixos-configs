{ config, pkgs, lib, ... }:

{
  # Add GitHub to known_hosts
  programs.ssh.knownHosts = {
    "github.com" = {
      hostNames = [ "github.com" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
  };

  # SSH client configuration for theophany
  programs.ssh.extraConfig = ''
    # Deploy key for system operations (darwin-rebuild, etc.)
    Host github-deploy.com
      HostName github.com
      User git
      IdentityFile /etc/ssh/theophany_deploy_key
      IdentitiesOnly yes
      StrictHostKeyChecking yes

    # User access for personal operations
    Host github.com
      HostName github.com
      PubkeyAuthentication yes
      IdentityFile ~/.ssh/id_rsa_yubikey.pub
      IdentitiesOnly yes
      User git

    Host *
      Protocol 2
      HashKnownHosts yes
      PasswordAuthentication yes
      StrictHostKeyChecking ask
      IdentityFile ~/.ssh/id_rsa_yubikey.pub
      IdentityFile ~/.ssh/id_ed25519
      VisualHostKey yes
      LogLevel DEBUG1
      User jason
  '';

  environment.systemPackages = with pkgs; [
    openssh
  ];
}
