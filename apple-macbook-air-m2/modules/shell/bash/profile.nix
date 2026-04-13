# Bash Profile Configuration - Environment and System Info
{ config, pkgs, lib, ... }:

{
  programs.bash.interactiveShellInit = ''
    # Shell options
    shopt -s autocd
    shopt -s cdspell
    shopt -s checkwinsize
    shopt -s cmdhist
    shopt -s histappend
    shopt -s nocaseglob

    # Key bindings
    bind '\C-l:clear-screen'
    bind '\C-u:kill-whole-line'

    # History configuration
    export HISTCONTROL='ignoreboth:erasedups'
    export HISTFILE=~/.bash_history
    export HISTFILESIZE=10000
    export HISTSIZE=10000
    export HISTTIMEFORMAT='%Y-%m-%d %H:%M:%S '

    # Environment variables
    export EDITOR='vim'
    export PAGER='less'
    export LESS='-sCMR'
    export MORE='-c'
    export GPG_TTY=$(tty)
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

    # System information on login
    if shopt -q login_shell && [[ $- == *i* ]]; then
      CACHE_FILE="$HOME/.bash_sysinfo_cache"
      CACHE_TTL=3600

      if [[ ! -f "$CACHE_FILE" ]]; then
        {
          echo "CACHED_HOSTNAME=$(hostname)"
          echo "DISK=$(df -h / 2>/dev/null | tail -1 | awk '{print $5 " used"}')"
        } > "$CACHE_FILE"
      else
        NOW=$(date +%s)
        FILE_TIME=$(stat -f "%m" "$CACHE_FILE" 2>/dev/null)
        [[ "$FILE_TIME" =~ ^[0-9]+$ ]] || FILE_TIME=0
        CACHE_AGE=$((NOW - FILE_TIME))
        if [[ $CACHE_AGE -gt $CACHE_TTL ]]; then
          {
            echo "CACHED_HOSTNAME=$(hostname)"
            echo "DISK=$(df -h / 2>/dev/null | tail -1 | awk '{print $5 " used"}')"
          } > "$CACHE_FILE"
        fi
      fi

      source "$CACHE_FILE" 2>/dev/null
      USERS=$(w -h | cut -d ' ' -f1 | sort | uniq | tr '\n' ' ')
      UPTIME=$(uptime | sed 's/.*up /up /')

      # Travel mode status
      if [[ "$(/usr/bin/defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState 2>/dev/null)" == "0" ]]; then
        TRAVEL="\033[1;33mON\033[0m"
      else
        TRAVEL="off"
      fi

      echo -e "\n\033[1;31m$CACHED_HOSTNAME\033[0m | $(date '+%Y-%m-%d %H:%M:%S') | $UPTIME"
      echo -e "\033[1;31mUsers:\033[0m $USERS | \033[1;31mDisk:\033[0m $DISK | \033[1;31mTravel:\033[0m $TRAVEL\n"

      vocab 2>/dev/null || true
      echo
    fi
  '';
}
