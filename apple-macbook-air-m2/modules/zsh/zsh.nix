# Main Zsh Configuration Module with oh-my-zsh
{ config, pkgs, lib, ... }:

{
  imports = [
    ./profile.nix
    ./aliases.nix
    ./vocab.nix
  ];

  # Enable zsh with oh-my-zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    interactiveShellInit = ''
      # Oh-My-Zsh setup
      export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"
      export ZSH_THEME="robbyrussell"
      plugins=(git)

      # Disable oh-my-zsh auto-update
      zstyle ':omz:update' mode disabled
      DISABLE_AUTO_UPDATE="true"

      # Load oh-my-zsh
      source $ZSH/oh-my-zsh.sh

      # Enable direnv
      eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
    '';
  };

  environment.systemPackages = with pkgs; [
    oh-my-zsh
  ];
}
