# Modern Bash Configuration - Framework Desktop
{ config, pkgs, lib, ... }:

{
  # Enhanced bash configuration
  programs.bash = {
    completion.enable = true;
    enableLsColors = true;

    # Global bash configuration
    interactiveShellInit = ''
      # Modern bash options
      set -o vi                    # Vi mode
      shopt -s autocd              # Auto cd into directories
      shopt -s cdspell             # Minor spelling correction for cd
      shopt -s checkwinsize        # Update LINES and COLUMNS after each command
      shopt -s cmdhist             # Save multi-line commands in history
      shopt -s histappend          # Append to history, don't overwrite
      shopt -s nocaseglob          # Case-insensitive globbing

      # History configuration
      export HISTCONTROL='ignoreboth:erasedups'
      export HISTFILESIZE=10000
      export HISTSIZE=10000
      export HISTTIMEFORMAT='%Y-%m-%d %H:%M:%S '
      export PROMPT_COMMAND="history -n; history -w; history -c; history -r"

      # Environment variables
      export EDITOR='vim'
      export PAGER='less'
      export LESS='-sCMR'
      export GPG_TTY=$(tty)
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

      # Modern color support
      if command -v dircolors >/dev/null 2>&1; then
        if [[ -r ~/.dircolors ]]; then
          eval "$(dircolors -b ~/.dircolors)"
        else
          eval "$(dircolors -b)"
        fi
      fi
    '';

    # Aliases
    shellAliases = {
      # Core commands
      "sudo" = "doas";
      "vi" = "vim";
      "ll" = "ls -la";
      "la" = "ls -la";
      "l" = "ls -CF";

      # Nix shortcuts
      "nrb" = "doas nixos-rebuild switch";
      "nrt" = "doas nixos-rebuild test";
      "nrs" = "nixos-rebuild switch --flake .#";
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
    };

    # Custom prompt with git integration
    promptInit = ''
      # Colors
      RED='\[\033[0;31m\]'
      GREEN='\[\033[0;32m\]'
      YELLOW='\[\033[0;33m\]'
      BLUE='\[\033[0;34m\]'
      PURPLE='\[\033[0;35m\]'
      CYAN='\[\033[0;36m\]'
      WHITE='\[\033[0;37m\]'
      BOLD='\[\033[1m\]'
      RESET='\[\033[0m\]'

      # Git branch function
      parse_git_branch() {
        if git rev-parse --git-dir >/dev/null 2>&1; then
          local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
          if [[ -n $branch ]]; then
            # Check for uncommitted changes
            if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
              echo " ''${YELLOW}(''${branch}*)''${RESET}"
            else
              echo " ''${GREEN}(''${branch})''${RESET}"
            fi
          fi
        fi
      }

      # Status indicator
      status_indicator() {
        if [[ $? -eq 0 ]]; then
          echo "''${GREEN}✓''${RESET}"
        else
          echo "''${RED}✗''${RESET}"
        fi
      }

      # Dynamic prompt
      PS1="''${CYAN}''${BOLD}\u@\h''${RESET} ''${BLUE}\w''${RESET}\$(parse_git_branch) \$(status_indicator) ''${PURPLE}→''${RESET} "
      PS2="''${YELLOW}→ ''${RESET}"
      PS3="''${YELLOW}#? ''${RESET}"
      PS4="''${RED}+ ''${RESET}"
    '';
  };

  # Shell functions
  environment.shellInit = ''
    # Modern extract function
    extract() {
      if [[ ! -f "$1" ]]; then
        echo "'$1' is not a valid file"
        return 1
      fi

      case "$1" in
        *.tar.bz2)   tar xjf "$1"    ;;
        *.tar.gz)    tar xzf "$1"    ;;
        *.tar.xz)    tar xJf "$1"    ;;
        *.bz2)       bunzip2 "$1"    ;;
        *.rar)       unrar x "$1"    ;;
        *.gz)        gunzip "$1"     ;;
        *.tar)       tar xf "$1"     ;;
        *.tbz2)      tar xjf "$1"    ;;
        *.tgz)       tar xzf "$1"    ;;
        *.zip)       unzip "$1"      ;;
        *.Z)         uncompress "$1" ;;
        *.7z)        7z x "$1"       ;;
        *.xz)        unxz "$1"       ;;
        *.lzma)      unlzma "$1"     ;;
        *)           echo "Unsupported archive format: $1" ;;
      esac
    }

    # Find files by name pattern
    ff() {
      find . -type f -iname "*$**" 2>/dev/null
    }

    # System information function
    sysinfo() {
      echo -e "\n''${BOLD}System Information:''${RESET}"
      echo "Hostname: $(hostnamectl --static 2>/dev/null || hostname)"
      echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
      echo "Load: $(cat /proc/loadavg | cut -d' ' -f1-3)"
      echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
      echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
      echo "IP: $(ip route get 1 2>/dev/null | awk '{print $7; exit}' || echo 'Not connected')"
      echo ""
    }

    # File swapping function
    swap() {
      if [[ $# -ne 2 ]]; then
        echo "Usage: swap file1 file2"
        return 1
      fi

      if [[ ! -e "$1" ]] || [[ ! -e "$2" ]]; then
        echo "Both files must exist"
        return 1
      fi

      local tmpfile=$(mktemp)
      mv "$1" "$tmpfile" && mv "$2" "$1" && mv "$tmpfile" "$2"
    }

    # Improved disk usage function
    disk_usage() {
      local target=''${1:-.}
      if [[ ! -d "$target" ]]; then
        echo "Directory '$target' not found"
        return 1
      fi
      du -h "$target"/* 2>/dev/null | sort -hr | head -20
    }

    # Modern process search
    psg() {
      if [[ -z "$1" ]]; then
        echo "Usage: psg <pattern>"
        return 1
      fi
      ps aux | grep -v grep | grep --color=always "$1"
    }
  '';

  # Vocab functionality as a separate script
  environment.systemPackages = with pkgs; [
    (writeScriptBin "vocab" ''
      #!${pkgs.bash}/bin/bash
      # Modern vocabulary script

      # Word arrays (truncated for space - include full arrays in actual implementation)
      declare -a words=(
        "ABATE:TO DECREASE; REDUCE"
        "ABDICATE:TO GIVE UP A POSITION, RIGHT, OR POWER"
        "ABERRANT:DEVIATING FROM WHAT IS NORMAL"
        "ABEYANCE:TEMPORARY SUPPRESSION OR SUSPENSION"
        "ABJECT:MISERABLE; PITIFUL"
        "ABJURE:TO REJECT; ABANDON FORMALLY"
        # ... (include all words from original .vocab file)
      )

      # Colors
      RED='\033[1;31m'
      YELLOW='\033[1;33m'
      PURPLE='\033[0;35m'
      BOLD='\033[1m'
      NC='\033[0m'

      # Select random word
      word_entry=''${words[$((RANDOM % ''${#words[@]}))]}
      word=''${word_entry%:*}
      meaning=''${word_entry#*:}

      # Display
      printf "''${BOLD}WORD OF THE SESSION: ''${YELLOW}%s''${NC}\n" "$word"
      printf "''${BOLD}MEANING            : ''${PURPLE}%s''${NC}\n" "$meaning"
      echo
    '')
  ];
}