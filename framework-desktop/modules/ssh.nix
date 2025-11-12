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

  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 6666;
      hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" ];
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQRbcTH0OZCQciQLgFXDqqqbc0383pXA/65JlZqpCyQ jason@scalene.local"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICUc9Otz8oBlWJ1y5oc9x2dBnSJ4Zi3rzJnlAz+eEV7 jason@theophany.local"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdTRD5etaWB3UmGiJ2cD/TVCn/asEw7c8frhAYDOhsb1bmEp7z3mG7gKFwepBaWFX3D7aXXirTTNsnKd7AsM5riQQg1tZ5qtmT+nEmpDhi1WVtFm89jc0ezyJN1SnlsCUEhQ0twn4qzR+PnjRVE1E4KTpbwTCapgMl9w4iCEQikaPWWcg9u+CRGNLaehgM7Jm5jKdVoIa258wNgvCrNZcba4LCccz1PK5j4j1uu3sr400CatIEkWe+aqiDCBIamFPXuJqZy1gb4+dqk1wKPJqn8L9WFD6j5mDarrIaHHmy7rnviPinbpLoCE3eksxAVeI1QjI8uPXyrn4GtUQNSNBMZPu2DTCZSo5bG5NbcE2Di9KSkW8SQJg0dYgZSJjssp5qkT9uFx7AnLfvIlR3+IQA45cXnM+jXCikNbGPLMenv8jjMrSke73hxr8T6rsjO2FGT3tWeiDBN5B59wgWY+bbrExOcFe2/cClYfBFzdF9d800Xg6+fN7E6gamTyrNNRL68f+sawuTDBrWggPJFFcHvQMd4zxE/ujbyCgy+11U8M5AAU/y6/Aa2XUt0jnEXgMXBpo7M3/5OWRzzyCO2RwtDWVxrJXPW9xYGvSoPAfDmdi0VNiGyldvbw4HHcHiFqftTCrNzMbR/QbjsuF4HMGI4fXddWYOFlNHbv+X+O2/kQ== cardno:5252959"
      ];
      shell = "/bin/cryptsetup-askpass";
    };
    postCommands = ''
      echo "LUKS unlocked successfully. System will continue booting..."
      exit 0
    '';
  };

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