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
      # Initialize starship prompt
      eval "$(${pkgs.starship}/bin/starship init zsh)"
    '';
  };

  environment.systemPackages = with pkgs; [
    starship
  ];

  # Starship configuration
  system.activationScripts.postActivation.text = ''
    USER_HOME="/Users/${config.system.primaryUser}"
    mkdir -p "$USER_HOME/.config"
    cat > "$USER_HOME/.config/starship.toml" << 'STARSHIP_EOF'
# Minimal prompt inspired by robbyrussell
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
# Don't use $all_status — starship 1.25 prepends a literal '$' to its output.
# Listing the individual status variables explicitly renders cleanly.
format = "[$conflicted$stashed$deleted$renamed$modified$staged$untracked$ahead_behind]($style) "
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
