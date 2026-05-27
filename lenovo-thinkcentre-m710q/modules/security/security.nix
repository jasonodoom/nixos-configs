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
          sha256 = "sha256-Tq8Y5X/6ZWq64FQ3m4F3Gjd9uxfTHuqe4ycz1XuTMS4=";
        })
      ];
    };
    # Root login disabled - use SSH with authorized keys only
    users.root.hashedPassword = "!";  # Locked account
  };

  # Doas configuration. keepEnv is off so doas does not inherit the caller's
  # environment (LD_PRELOAD, PATH, etc.) into the privileged session.
  security.doas = {
    enable = true;
    extraRules = [{
      users = [ "amy" ];
      persist = true;
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
