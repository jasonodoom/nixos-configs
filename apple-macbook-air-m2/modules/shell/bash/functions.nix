# Bash Functions Configuration
{ config, pkgs, lib, ... }:

{
  programs.bash.interactiveShellInit = ''
    # Extract archives
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
        *)           echo "Unsupported archive format: $1" ;;
      esac
    }

    # Find files by name
    ff() {
      find . -type f -iname "*$1*" 2>/dev/null
    }

    # Process search
    psg() {
      if [[ -z "$1" ]]; then
        echo "Usage: psg <pattern>"
        return 1
      fi
      ps aux | grep -v grep | grep --color=always "$1"
    }

    # File swap
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

    # Disk usage top 20
    disk_usage() {
      local target=''${1:-.}
      if [[ ! -d "$target" ]]; then
        echo "Directory '$target' not found"
        return 1
      fi
      du -h "$target"/* 2>/dev/null | sort -hr | head -20
    }

    # FZF integration
    if command -v fzf >/dev/null 2>&1; then
      __fzf_history() {
        local selected
        selected=$(HISTTIMEFORMAT= history | fzf --tac --no-sort --query="$READLINE_LINE" | sed 's/^ *[0-9]* *//')
        if [[ -n "$selected" ]]; then
          READLINE_LINE="$selected"
          READLINE_POINT=''${#READLINE_LINE}
        fi
      }
      bind '"\C-r": "\C-x1"'
      bind -x '"\C-x1": __fzf_history'
    fi
  '';
}
