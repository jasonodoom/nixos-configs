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
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null || echo "")
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
    if [[ -o interactive ]]; then
      echo -e "\nYou are logged on \033[1;31m$(hostname)\033[0m"
      echo -e "\n\033[1;31mAdditional information:\033[0m"; uname -a
      echo -e "\n\033[1;31mUsers logged on:\033[0m"; w -h | cut -d " " -f1 | sort | uniq
      echo -e "\n\033[1;31mCurrent date:\033[0m"; date
      echo -e "\n\033[1;31mMachine stats:\033[0m"; uptime
      echo -e "\n\033[1;31mDiskspace:\033[0m"; df -h / 2>/dev/null | tail -1
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
      date
      echo
    fi
  '';
}
