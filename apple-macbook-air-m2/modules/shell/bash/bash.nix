# Main Bash Configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ./profile.nix
    ./aliases.nix
    ./functions.nix
    ./vocab.nix
    ./agent-sessions.nix
  ];

  programs.bash = {
    enable = true;
    completion.enable = true;
    interactiveShellInit = ''
      eval "$(${pkgs.starship}/bin/starship init bash)"
    '';
  };

  users.users.jason.shell = pkgs.bash;

  # Readline configuration
  environment.etc."inputrc".text = ''
    "\e[A": history-search-backward
    "\e[B": history-search-forward
    "\e[C": forward-char
    "\e[D": backward-char
    set input-meta on
    set output-meta on
    set convert-meta off
    set show-all-if-ambiguous on
    set completion-ignore-case on
    set mark-symlinked-directories on
    set visible-stats on
  '';

  environment.systemPackages = [ pkgs.bashInteractive ];

  # Register Nix bash as a valid login shell
  environment.shells = [ pkgs.bashInteractive ];

  # Set bash as default shell
  system.activationScripts.postActivation.text = ''
    dscl . -create /Users/${config.system.primaryUser} UserShell "/run/current-system/sw/bin/bash"
  '';
}
