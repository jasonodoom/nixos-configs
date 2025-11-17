# Zsh Aliases Configuration (from your .bashrcd/.aliases)
{ config, pkgs, lib, ... }:

{
  programs.zsh.interactiveShellInit = ''
    # Core commands
    alias nano='vim'
    alias vi='vim'
    alias ll='ls -ltra'
    alias weather='curl wttr.in'
    alias password='openssl rand -base64 32'
    alias killgpg='gpgconf --kill gpg-agent'
    alias fixssh='chmod 700 ~/.ssh && chmod 644 ~/.ssh/authorized_keys && chmod 600 ~/.ssh/*_rsa ~/.ssh/*_ed25519'

    # File operations
    alias 100mb='dd if=/dev/zero of=100mb.file bs=100 count=1024000'
    alias 1gb='dd if=/dev/zero of=1gb.file bs=1000 count=1024000'
    alias ducks='du -chs * | sort -rh | head'
    alias shredhere='find ./ -type f -exec shred -uv {} \;'

    # Git shortcuts
    alias k='kubectl'

    # Nix shortcuts
    alias ncg='nix-collect-garbage -d'
    alias dgo='nix-env --delete-generations old'
    alias gcn='nix-collect-garbage --delete-older-than 1s'
    alias nix_clean='nix-collect-garbage --delete-older-than 1s && nix-collect-garbage -d'
    alias drb='darwin-rebuild switch --flake ~/.config/nix-darwin'
    alias drs='darwin-rebuild switch --flake .#theophany'

    # Tailscale
    alias tailscale='/Applications/Tailscale.app/Contents/MacOS/Tailscale'
  '';
}
