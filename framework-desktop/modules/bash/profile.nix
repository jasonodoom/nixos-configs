# Bash Profile Configuration - Environment and System Info
{ config, pkgs, lib, ... }:

{
  programs.bash.interactiveShellInit = ''
    # Bash options
    shopt -s autocd              # Auto cd into directories
    shopt -s cdspell             # Minor spelling correction for cd
    shopt -s checkwinsize        # Update LINES and COLUMNS after each command
    shopt -s cmdhist             # Save multi-line commands in history
    shopt -s histappend          # Append to history, don't overwrite
    shopt -s nocaseglob          # Case-insensitive globbing

    # Key bindings
    bind '\C-l:clear-screen'     # Ctrl+L to clear screen
    bind '\C-u:kill-whole-line'  # Ctrl+U to clear line

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
    export MORE='-c'
    export GPG_TTY=$(tty)
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    export KEYID='0x68CCAF80768A91A5'

    # System information
    export MACHINE=$(uname -s)
    export HOST=$(uname -n)
    export PLATFORM=$(uname -p)

    # Prevent programs from opening gnome dialogues for users and password
    unset SSH_ASKPASS

    # Set umask so that default permission is 750
    umask 027

    # Color support
    if command -v dircolors >/dev/null 2>&1; then
      if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
      else
        eval "$(dircolors -b)"
      fi
    fi

    # System information on login
    if [[ $- == *i* ]]; then
      echo -e "\nYou are logged on \033[1;31m$(hostname)\033[0m"
      echo -e "\n\033[1;31mAdditional information:\033[0m"; uname -a
      echo -e "\n\033[1;31mUsers logged on:\033[0m"; w -hs | cut -d " " -f1 | sort | uniq
      echo -e "\n\033[1;31mCurrent date:\033[0m"; date
      echo -e "\n\033[1;31mMachine stats:\033[0m"; uptime
      echo -e "\n\033[1;31mMemory stats:\033[0m"; free -h 2>/dev/null || echo "free command not available"
      echo -e "\n\033[1;31mDiskspace:\033[0m"; df -h / 2>/dev/null | tail -1 || echo "df command not available"
      echo -e "\n\033[1;31mLocal IP Address:\033[0m"; ip route get 1 2>/dev/null | awk '{print $7; exit}' || echo "Not connected"
      echo -e "\n\033[1;31mOpen connections:\033[0m"; netstat -tul --inet 2>/dev/null | head -10 || ss -tuln | head -10
      echo

      # Session status if available
      echo -e "\033[1;31mSessions:\033[0m"
      if command -v screen >/dev/null 2>&1; then
        screen_count=$(screen -ls 2>/dev/null | grep -c "Detached\|Attached" || echo "0")
        echo "  Screen: $screen_count sessions"
      fi
      if command -v tmux >/dev/null 2>&1; then
        tmux_count=$(tmux list-sessions 2>/dev/null | wc -l || echo "0")
        echo "  Tmux: $tmux_count sessions"
      fi

      echo -e "\n\033[1;31mThe Date & Time is:\033[0m"
      date -R
      echo

      # Run vocab on shell start
      vocab 2>/dev/null || true
      echo
    fi
  '';
}