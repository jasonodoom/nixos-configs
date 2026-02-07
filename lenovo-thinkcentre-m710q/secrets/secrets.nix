# Agenix secrets configuration file for Congo server

let
  # User SSH keys
  jason-scalene = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQRbcTH0OZCQciQLgFXDqqqbc0383pXA/65JlZqpCyQ jason@scalene.local";
  jason-theophany = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICUc9Otz8oBlWJ1y5oc9x2dBnSJ4Zi3rzJnlAz+eEV7 jason@theophany.local";
  jason-perdurabo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwLk94aSzaUrpxHZ6BHbxMaF3054VZJh6rUF8cdSHIm jason@perdurabo";
  jason-yk = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdTRD5etaWB3UmGiJ2cD/TVCn/asEw7c8frhAYDOhsb1bmEp7z3mG7gKFwepBaWFX3D7aXXirTTNsnKd7AsM5riQQg1tZ5qtmT+nEmpDhi1WVtFm89jc0ezyJN1SnlsCUEhQ0twn4qzR+PnjRVE1E4KTpbwTCapgMl9w4iCEQikaPWWcg9u+CRGNLaehgM7Jm5jKdVoIa258wNgvCrNZcba4LCccz1PK5j4j1uu3sr400CatIEkWe+aqiDCBIamFPXuJqZy1gb4+dqk1wKPJqn8L9WFD6j5mDarrIaHHmy7rnviPinbpLoCE3eksxAVeI1QjI8uPXyrn4GtUQNSNBMZPu2DTCZSo5bG5NbcE2Di9KSkW8SQJg0dYgZSJjssp5qkT9uFx7AnLfvIlR3+IQA45cXnM+jXCikNbGPLMenv8jjMrSke73hxr8T6rsjO2FGT3tWeiDBN5B59wgWY+bbrExOcFe2/cClYfBFzdF9d800Xg6+fN7E6gamTyrNNRL68f+sawuTDBrWggPJFFcHvQMd4zxE/ujbyCgy+11U8M5AAU/y6/Aa2XUt0jnEXgMXBpo7M3/5OWRzzyCO2RwtDWVxrJXPW9xYGvSoPAfDmdi0VNiGyldvbw4HHcHiFqftTCrNzMbR/QbjsuF4HMGI4fXddWYOFlNHbv+X+O2/kQ== cardno:5252959";

  # Congo host key 
  # /etc/ssh/ssh_host_ed25519_key.pub
  congo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQYx0WE2JTLlywkZ5FCn+CoeRU4mBpcGEBTwzNwjpw+ root@congo";

  # User keys that can decrypt secrets
  users = [ jason-scalene jason-theophany jason-perdurabo jason-yk ];

  # System keys
  systems = [ congo ];

  # All keys that can decrypt (user and system keys)
  all = users ++ systems;
in
{
  # User password secret
  "amy-password.age".publicKeys = all;

  # Initrd SSH host key for remote LUKS unlock
  "initrd-ssh-host-ed25519-key.age".publicKeys = all;

  # Pi-hole admin password
  "pihole-admin-password.age".publicKeys = all;

  # Tailscale auth key for initrd remote LUKS unlock
  # Expires: 2026-02-10
  "tailscale-initrd-key.age".publicKeys = all;

  # GitHub token for creating issues on auto-upgrade failures
  "gh-token.age".publicKeys = all;

  # Temporarily disabled - will be enabled when needed
  # # SSH client configuration
  # "ssh-config.age".publicKeys = all;

  # # OpenBao configuration
  # "openbao-config.age".publicKeys = all;
}