# Main Bash Configuration Module
{ config, pkgs, lib, ... }:

{
  imports = [
    ./profile.nix
    ./aliases.nix
    ./colors.nix
    ./functions.nix
    ./vocab.nix
  ];

  # Enable bash completion and colors
  programs.bash = {
    completion.enable = true;
    enableLsColors = true;
  };
}