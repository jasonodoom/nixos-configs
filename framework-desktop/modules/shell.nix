# Shell Configuration - Framework Desktop
{ config, pkgs, ... }:

{
  # Shell programs
  programs = {
    zsh.enable = true;

    # Direnv for development environments
    direnv.enable = true;
  };

  # Environment configuration
  environment = {
    # Global environment variables
    variables = {
      EDITOR = "vim";
      LANG = "en_US.UTF-8";
      GPG_TTY = "$(tty)";

      # Development tools
      MOB_TIMER_ROOM = "diligent-flea-68";
    };

    # Shell initialization for all shells
    interactiveShellInit = ''
      # GPG and SSH agent configuration
      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

      # History settings for bash
      export HISTCONTROL=ignoreboth:erasedups
      export HISTFILESIZE=4096
      export HISTSIZE=4096
      export PROMPT_COMMAND="history -n; history -w; history -c; history -r"

      # Path additions
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin"

      # Bash silence deprecation warning (macOS)
      export BASH_SILENCE_DEPRECATION_WARNING=1

      # System update alias
      alias update-system='doas nixos-rebuild switch --flake "github:jasonodoom/nixos-configs?dir=framework-desktop#perdurabo" --refresh'

    '';

    # Bash-specific prompt configuration
    shellInit = ''
      # Colors for bash prompt
      RED="\[\033[0;31m\]"
      BROWN="\[\033[0;33m\]"
      GREY="\[\033[0;97m\]"
      GREEN="\[\033[0;32m\]"
      BLUE="\[\033[0;34m\]"
      PS_CLEAR="\[\033[0m\]"

      # Git branch parser for bash
      parse_git_branch() {
        [ -d .git ] || return 1
        git symbolic-ref HEAD 2> /dev/null | sed 's#\(.*\)\/\([^\/]*\)$# \2#'
      }

      # Colored prompt for bash
      if [ -n "$BASH_VERSION" ]; then
        PS1="''${GREEN}\W\$(parse_git_branch) → ''${GREY}"
        PS2="\[[33;1m\]continue \[[0m[1m\]> "
      fi
    '';
  };
}