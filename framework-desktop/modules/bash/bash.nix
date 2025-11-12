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

  # Readline configuration for proper arrow key history navigation
  environment.etc."inputrc".text = ''
    # Arrow key history search
    "\e[A": history-search-backward
    "\e[B": history-search-forward
    "\e[C": forward-char
    "\e[D": backward-char

    # Enable 8-bit input
    set input-meta on
    set output-meta on
    set convert-meta off

    # Completion settings
    set show-all-if-ambiguous on
    set completion-ignore-case on
    set mark-symlinked-directories on
    set visible-stats on
  '';
}