# Zsh Profile Configuration - Environment and System Info
{ config, pkgs, lib, ... }:

{
  programs.zsh.interactiveShellInit = ''
    # Zsh options
    setopt AUTO_CD              # Auto cd into directories
    setopt CORRECT              # Command correction
    setopt HIST_IGNORE_ALL_DUPS # Remove older duplicate entries from history
    setopt HIST_REDUCE_BLANKS   # Remove superfluous blanks from history items
    setopt INC_APPEND_HISTORY   # Save history entries as soon as they are entered
    setopt SHARE_HISTORY        # Share history between sessions
    setopt EXTENDED_GLOB        # Extended globbing

    # History configuration
    export HISTFILE=~/.zsh_history
    export HISTSIZE=10000
    export SAVEHIST=10000

    # Environment variables
    export EDITOR='vim'
    export PAGER='less'
    export LESS='-sCMR'
    export MORE='-c'
    export GPG_TTY=$(tty)
    # Only set SSH_AUTH_SOCK if gpgconf is available and agent socket exists
    if command -v gpgconf >/dev/null 2>&1; then
      AGENT_SOCK=$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null)
      [[ -S "$AGENT_SOCK" ]] && export SSH_AUTH_SOCK="$AGENT_SOCK"
    fi
    export KEYID='0x68CCAF80768A91A5'

    # System information
    export MACHINE=$(uname -s)
    export HOST=$(uname -n)
    export PLATFORM=$(uname -p)

    # Prevent programs from opening dialogues for password
    unset SSH_ASKPASS

    # Set umask so that default permission is 750
    umask 027

    # Color support for macOS
    export CLICOLOR=1
    export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd

    # System information on login with selective caching
    if [[ -o login ]] && [[ -o interactive ]]; then
      CACHE_FILE="$HOME/.zsh_sysinfo_cache"
      CACHE_TTL=3600  # 1 hour for rarely-changing data

      # Cache only static/slow-changing data (hostname, disk)
      if [[ ! -f "$CACHE_FILE" ]]; then
        {
          echo "HOSTNAME=$(hostname)"
          echo "DISK=$(df -h / 2>/dev/null | tail -1 | awk '{print $5 " used"}')"
        } > "$CACHE_FILE"
      else
        # Check cache age using touch comparison
        NOW=$(date +%s)
        FILE_TIME=$(stat -f "%m" "$CACHE_FILE" 2>/dev/null)
        # Ensure FILE_TIME is numeric, default to 0 if not
        [[ "$FILE_TIME" =~ ^[0-9]+$ ]] || FILE_TIME=0
        CACHE_AGE=$((NOW - FILE_TIME))
        if [[ $CACHE_AGE -gt $CACHE_TTL ]]; then
          {
            echo "HOSTNAME=$(hostname)"
            echo "DISK=$(df -h / 2>/dev/null | tail -1 | awk '{print $5 " used"}')"
          } > "$CACHE_FILE"
        fi
      fi

      # Load cached values and fetch fresh dynamic data
      source "$CACHE_FILE" 2>/dev/null
      USERS=$(w -h | cut -d ' ' -f1 | sort | uniq | tr '\n' ' ')
      UPTIME=$(uptime | sed 's/.*up /up /')

      echo -e "\n\033[1;31m$HOSTNAME\033[0m | $(date '+%Y-%m-%d %H:%M:%S') | $UPTIME"
      echo -e "\033[1;31mUsers:\033[0m $USERS | \033[1;31mDisk:\033[0m $DISK\n"
    fi
  '';
}
