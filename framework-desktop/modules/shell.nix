# Shell Configuration - Framework Desktop
{ config, pkgs, ... }:

{
  # Shell programs
  programs = {
    # Direnv for development environments
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  # Environment configuration
  environment = {
    # Global environment variables
    variables = {
      EDITOR = "nvim";
      LANG = "en_US.UTF-8";
      GPG_TTY = "$(tty)";

      # Development tools
      MOB_TIMER_ROOM = "diligent-flea-68";
    };

    # Shell initialization for all shells (non-bash specific)
    interactiveShellInit = ''
      # GPG and SSH agent configuration
      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

      # Path additions
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin"
    '';
  };
}