# Main Bash Configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ./profile.nix
    ./aliases.nix
    ./functions.nix
    ./vocab.nix
  ];

  programs.bash = {
    enable = true;
    completion.enable = true;
    interactiveShellInit = ''
      eval "$(${pkgs.starship}/bin/starship init bash)"
    '';
  };

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

  environment.systemPackages = with pkgs; [
    starship
    bashInteractive
  ];

  # Register Nix bash as a valid login shell
  environment.shells = [ pkgs.bashInteractive ];

  # Set bash as default shell
  system.activationScripts.set-default-shell.text = ''
    dscl . -create /Users/${config.system.primaryUser} UserShell "/run/current-system/sw/bin/bash"
  '';

  # Starship configuration
  system.activationScripts.starship-config.text = ''
    USER_HOME="/Users/${config.system.primaryUser}"
    mkdir -p "$USER_HOME/.config"
    cat > "$USER_HOME/.config/starship.toml" << 'STARSHIP_EOF'
format = """$directory$git_branch$git_status$character"""

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[directory]
style = "bold cyan"
truncation_length = 1
truncate_to_repo = true

[git_branch]
format = "[($branch)]($style) "
style = "bold red"

[git_status]
format = "[$all_status$ahead_behind]($style) "
style = "bold red"
modified = "✗"
untracked = "?"
staged = "+"
ahead = "⇡"
behind = "⇣"
diverged = "⇕"

[cmd_duration]
disabled = true

[package]
disabled = true

[nodejs]
disabled = true

[python]
disabled = true

[rust]
disabled = true

[golang]
disabled = true
STARSHIP_EOF
    chmod 644 "$USER_HOME/.config/starship.toml"
    chown ${config.system.primaryUser}:staff "$USER_HOME/.config/starship.toml"
  '';
}
