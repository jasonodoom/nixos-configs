# Bash Aliases Configuration
{ config, pkgs, lib, ... }:

{
  programs.bash.shellAliases = {
    # Core commands
    "sudo" = "doas";
    "vi" = "vim";
    "ll" = "ls -la";
    "la" = "ls -la";
    "l" = "ls -CF";
    "ls" = "ls --color=auto";
    "dir" = "dir --color=auto";
    "vdir" = "vdir --color=auto";
    "grep" = "grep --color=auto";
    "fgrep" = "fgrep --color=auto";
    "egrep" = "egrep --color=auto";

    # Nix shortcuts
    "nrb" = "doas nixos-rebuild switch";
    "nrt" = "doas nixos-rebuild test";
    "nrs" = "nixos-rebuild switch --flake .#";
    "update-system" = ''doas nixos-rebuild switch --flake "git+ssh://git@github-deploy.com/jasonodoom/nixos-configs.git?dir=framework-desktop&ref=main#perdurabo" --refresh'';
    "ncg" = "nix-collect-garbage -d";
    "nix-clean" = "nix-collect-garbage --delete-older-than 7d && doas nix-collect-garbage -d";

    # Development
    "k" = "kubectl";
    "dc" = "docker-compose";

    # System utilities
    "weather" = "curl wttr.in";
    "password" = "openssl rand -base64 32";
    "port" = "doas netstat -tulpn | grep";
    "ducks" = "du -chs * | sort -rh | head";
    "myip" = "ip route get 1 | awk '{print $7; exit}'";

    # Safety aliases
    "rm" = "rm -i";
    "cp" = "cp -i";
    "mv" = "mv -i";

    # Git shortcuts
    "gs" = "git status";
    "ga" = "git add";
    "gc" = "git commit";
    "gp" = "git push";
    "gl" = "git pull";
    "gd" = "git diff";
    "gb" = "git branch";
    "gco" = "git checkout";
    "glog" = "git log --oneline --graph --decorate";

    # Hardware info aliases
    "asset-tag" = "doas dmidecode -s system-serial-number";
    "ram" = "doas dmidecode --type 17";

    # System utilities
    "stealth1" = "rm ~/.bash_history; history -c; export HISTFILESIZE=0; export HISTSIZE=0; unset HISTFILE";
    "stealth2" = "rm ~/.bash_history; ln /dev/null ~/.bash_history -sf";
    "killgpg" = "gpgconf --kill gpg-agent";
    "fixssh" = "chmod 700 ~/.ssh && chmod 644 ~/.ssh/authorized_keys && chmod 600 ~/.ssh/*_rsa";

    # File generation utilities
    "100mb" = "dd if=/dev/zero of=100mb.file bs=100 count=1024000";
    "1gb" = "dd if=/dev/zero of=1gb.file bs=1000 count=1024000";
    "shredhere" = "find ./ -type f -exec shred -uv {} \\;";
  };
}