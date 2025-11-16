# Agenix secrets configuration file
# This file defines which public keys can decrypt which secrets

let
  jason-scalene = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQRbcTH0OZCQciQLgFXDqqqbc0383pXA/65JlZqpCyQ jason@scalene.local";
  jason-theophany = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICUc9Otz8oBlWJ1y5oc9x2dBnSJ4Zi3rzJnlAz+eEV7 jason@theophany.local";
  jason-perdurabo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwLk94aSzaUrpxHZ6BHbxMaF3054VZJh6rUF8cdSHIm jason@perdurabo";
  jason-yk = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdTRD5etaWB3UmGiJ2cD/TVCn/asEw7c8frhAYDOhsb1bmEp7z3mG7gKFwepBaWFX3D7aXXirTTNsnKd7AsM5riQQg1tZ5qtmT+nEmpDhi1WVtFm89jc0ezyJN1SnlsCUEhQ0twn4qzR+PnjRVE1E4KTpbwTCapgMl9w4iCEQikaPWWcg9u+CRGNLaehgM7Jm5jKdVoIa258wNgvCrNZcba4LCccz1PK5j4j1uu3sr400CatIEkWe+aqiDCBIamFPXuJqZy1gb4+dqk1wKPJqn8L9WFD6j5mDarrIaHHmy7rnviPinbpLoCE3eksxAVeI1QjI8uPXyrn4GtUQNSNBMZPu2DTCZSo5bG5NbcE2Di9KSkW8SQJg0dYgZSJjssp5qkT9uFx7AnLfvIlR3+IQA45cXnM+jXCikNbGPLMenv8jjMrSke73hxr8T6rsjO2FGT3tWeiDBN5B59wgWY+bbrExOcFe2/cClYfBFzdF9d800Xg6+fN7E6gamTyrNNRL68f+sawuTDBrWggPJFFcHvQMd4zxE/ujbyCgy+11U8M5AAU/y6/Aa2XUt0jnEXgMXBpo7M3/5OWRzzyCO2RwtDWVxrJXPW9xYGvSoPAfDmdi0VNiGyldvbw4HHcHiFqftTCrNzMbR/QbjsuF4HMGI4fXddWYOFlNHbv+X+O2/kQ== cardno:5252959";
  hdd-backup = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGqpB62GkdvoDGnThDpLzCVsCZKiN8dNpxcwmpz08FrV jason@perdurabo-backup";


  # System host key (will be generated during installation)
  # /etc/ssh/ssh_host_ed25519_key.pub
  perdurabo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFXyQoWYsAd796hWs6RRr9RMlTboe4KBxqk6mS+Ia8qJ";

  # User keys that can decrypt secrets
  users = [ jason-scalene jason-theophany jason-perdurabo jason-yk hdd-backup ];

  # System keys (host keys)
  systems = [ perdurabo ];

  # All keys that can decrypt
  all = users ++ systems;
in
{
  # User password secret
  "jason-password.age".publicKeys = all;

  # SSH client configuration
  "ssh-config.age".publicKeys = all;

  # Tailscale auth key for initrd remote LUKS unlock
  # Expires: 2026-02-11
  "tailscale-initrd-key.age".publicKeys = all;

  # Code-server password for Settings Sync
  "code-server-password.age".publicKeys = all;
}