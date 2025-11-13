# Bash Profile Configuration for Congo Server
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

    # Server environment variables
    export EDITOR='vim'
    export PAGER='less'
    umask 027

    # Congo text in flag colors
    congo_flag() {
      echo
      echo -e "        \033[1;44m \033[1;34mC \033[0m\033[1;43m \033[1;33mO \033[0m\033[1;41m \033[1;31mN \033[0m\033[1;43m \033[1;33mG \033[0m\033[1;44m \033[1;34mO \033[0m"
      echo
    }

    # Server info on login
    if [[ $- == *i* ]]; then
      congo_flag
      echo -e "\033[1;31mHostname:\033[0m \033[1;43m$(hostname)\033[0m"
      echo -e "\033[1;34mUsers:\033[0m $(w -h | wc -l) connected"
      echo -e "\033[1;31mNetwork:\033[0m"
      netstat -tuln | head -10
      echo
    fi
  '';
}