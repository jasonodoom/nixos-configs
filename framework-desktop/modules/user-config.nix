# User-specific configuration 
{ config, pkgs, lib, inputs, ... }:

{
  # User account
  users.users.jason = {
    isNormalUser = true;
    description = "Jason Odoom";
    extraGroups = [
      "wheel"           # sudo/doas access
      "audio"           # audio devices
      "video"           # video devices
      "networkmanager"  # network management
      "dialout"         # serial devices
      "docker"          # docker daemon
      "libvirtd"        # virtualization
      "kvm"             # kvm virtualization
      "input"           # input devices
    ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQRbcTH0OZCQciQLgFXDqqqbc0383pXA/65JlZqpCyQ jason@scalene.local"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdTRD5etaWB3UmGiJ2cD/TVCn/asEw7c8frhAYDOhsb1bmEp7z3mG7gKFwepBaWFX3D7aXXirTTNsnKd7AsM5riQQg1tZ5qtmT+nEmpDhi1WVtFm89jc0ezyJN1SnlsCUEhQ0twn4qzR+PnjRVE1E4KTpbwTCapgMl9w4iCEQikaPWWcg9u+CRGNLaehgM7Jm5jKdVoIa258wNgvCrNZcba4LCccz1PK5j4j1uu3sr400CatIEkWe+aqiDCBIamFPXuJqZy1gb4+dqk1wKPJqn8L9WFD6j5mDarrIaHHmy7rnviPinbpLoCE3eksxAVeI1QjI8uPXyrn4GtUQNSNBMZPu2DTCZSo5bG5NbcE2Di9KSkW8SQJg0dYgZSJjssp5qkT9uFx7AnLfvIlR3+IQA45cXnM+jXCikNbGPLMenv8jjMrSke73hxr8T6rsjO2FGT3tWeiDBN5B59wgWY+bbrExOcFe2/cClYfBFzdF9d800Xg6+fN7E6gamTyrNNRL68f+sawuTDBrWggPJFFcHvQMd4zxE/ujbyCgy+11U8M5AAU/y6/Aa2XUt0jnEXgMXBpo7M3/5OWRzzyCO2RwtDWVxrJXPW9xYGvSoPAfDmdi0VNiGyldvbw4HHcHiFqftTCrNzMbR/QbjsuF4HMGI4fXddWYOFlNHbv+X+O2/kQ== cardno:5252959"
    ];
    # Password will be managed via agenix secrets (disabled for initial install)
    # passwordFile = config.age.secrets.jason-password.path;
  };

  # Shell configuration moved to bash.nix module

}