# Age public keys for secret encryption
# This file defines which SSH public keys can decrypt secrets
let
  # User SSH public keys (for decryption on theophany)
  jason-theophany = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQRbcTH0OZCQciQLgFXDqqqbc0383pXA/65JlZqpCyQ jason@scalene.local";

  # SSH keys from GitHub (github.com/jasonodoom.keys)
  jason-github-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdTRD5etaWB3UmGiJ2cD/TVCn/asEw7c8frhAYDOhsb1bmEp7z3mG7gKFwepBaWFX3D7aXXirTTNsnKd7AsM5riQQg1tZ5qtmT+nEmpDhi1WVtFm89jc0ezyJN1SnlsCUEhQ0twn4qzR+PnjRVE1E4KTpbwTCapgMl9w4iCEQikaPWWcg9u+CRGNLaehgM7Jm5jKdVoIa258wNgvCrNZcba4LCccz1PK5j4j1uu3sr400CatIEkWe+aqiDCBIamFPXuJqZy1gb4+dqk1wKPJqn8L9WFD6j5mDarrIaHHmy7rnviPinbpLoCE3eksxAVeI1QjI8uPXyrn4GtUQNSNBMZPu2DTCZSo5bG5NbcE2Di9KSkW8SQJg0dYgZSJjssp5qkT9uFx7AnLfvIlR3+IQA45cXnM+jXCikNbGPLMenv8jjMrSke73hxr8T6rsjO2FGT3tWeiDBN5B59wgWY+bbrExOcFe2/cClYfBFzdF9d800Xg6+fN7E6gamTyrNNRL68f+sawuTDBrWggPJFFcHvQMd4zxE/ujbyCgy+11U8M5AAU/y6/Aa2XUt0jnEXgMXBpo7M3/5OWRzzyCO2RwtDWVxrJXPW9xYGvSoPAfDmdi0VNiGyldvbw4HHcHiFqftTCrNzMbR/QbjsuF4HMGI4fXddWYOFlNHbv+X+O2/kQ==";
  jason-yubikey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwLk94aSzaUrpxHZ6BHbxMaF3054VZJh6rUF8cdSHIm";

  # Perdurabo key (from framework-desktop)
  jason-perdurabo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCSqE56Z7PmlNBd+9wHIAi+3V9jL2KI+x3YZMR8GSSS jason@perdurabo";

  # All keys that can decrypt secrets
  allKeys = [ jason-perdurabo jason-yubikey jason-theophany ];
in
{

  #  Create the encrypted file with: agenix -e secrets/openai-api-key.age
  # "secrets/openai-api-key.age".publicKeys = allKeys;

  # GitHub token for creating issues on auto-upgrade failures
  "gh-token.age".publicKeys = allKeys;
}
