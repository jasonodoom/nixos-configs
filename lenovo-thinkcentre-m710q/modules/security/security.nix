# Security configuration for Congo server
{ config, pkgs, lib, ... }:

{
  # User configuration
  users = {
    mutableUsers = false;  # Disable password changes, use agenix secrets
    users.amy = {
      isNormalUser = true;
      # Password hash managed by agenix secret
      hashedPasswordFile = config.age.secrets.amy-password.path;
      extraGroups = [ "wheel" "networkmanager" ];
      openssh.authorizedKeys.keyFiles = [
        (builtins.fetchurl {
          url = "https://github.com/jasonodoom.keys";
          sha256 = "sha256-M2J93LuP+ZTfWjWkChQMLcX8ogINJ6xfKvZngmbz6qE=";
        })
      ];
    };
    # Root login disabled - use SSH with authorized keys only
    users.root.hashedPassword = "!";  # Locked account
  };

  # Doas configuration
  security.doas = {
    enable = true;
    extraRules = [{
      users = [ "amy" ];
      keepEnv = true;
      persist = true;  # Remember authentication for a session
    }];
  };

  # Disable sudo
  security.sudo.enable = false;

  # PAM configuration
  security.pam.loginLimits = [
    { domain = "@wheel"; item = "nofile"; type = "soft"; value = "524288"; }
    { domain = "@wheel"; item = "nofile"; type = "hard"; value = "1048576"; }
  ];

  # System packages for security and administration
  environment.systemPackages = with pkgs; [
    vim
    htop
    git
    curl
    wget
    tmux
    ragenix
  ];
}