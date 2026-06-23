# Main Zsh Configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ./profile.nix
    ./aliases.nix
    ./vocab.nix
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    interactiveShellInit = ''
      eval "$(${pkgs.starship}/bin/starship init zsh)"
    '';
  };
}
