# Bash Colors and Prompt Configuration - Congo Theme
{ config, pkgs, lib, ... }:

{
  programs.bash.promptInit = ''
    # Congo flag colors for PS1
    CONGO_BLUE='\[\033[0;34m\]'     # Blue
    CONGO_YELLOW='\[\033[1;43m\]'   # Yellow background
    CONGO_RED='\[\033[0;31m\]'      # Red
    BLUE='\[\033[0;34m\]'
    YELLOW='\[\033[1;33m\]'
    RED='\[\033[0;31m\]'
    WHITE='\[\033[0;37m\]'
    BOLD='\[\033[1m\]'
    RESET='\[\033[0m\]'

    # Raw color codes for echo statements
    C_BLUE="\033[0;34m"
    C_YELLOW="\033[1;33m"
    C_RED="\033[0;31m"
    C_BOLD="\033[1m"
    C_RESET="\033[0m"

    # Status indicator with Congo flag
    status_indicator() {
      local exit_code=$1
      if [[ $exit_code -eq 0 ]]; then
        echo -e "🇨🇩"
      else
        echo -e "\033[1;31m✗\033[0m"   # Red X
      fi
    }

    # Server load indicator
    load_indicator() {
      local load=$(uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }' | sed 's/,//')
      local load_int=$(echo "$load" | cut -d. -f1)

      if [[ $load_int -lt 1 ]]; then
        echo -e "\033[1;34m●\033[0m"  # Blue - low load
      elif [[ $load_int -lt 2 ]]; then
        echo -e "\033[1;33m●\033[0m"  # Yellow - medium load
      else
        echo -e "\033[1;31m●\033[0m"  # Red - high load
      fi
    }

    # Congo-themed PS1
    PS1="''${BOLD}''${CONGO_BLUE}\u''${RESET}''${BOLD}@''${CONGO_YELLOW}\h''${RESET} ''${CONGO_RED}\w''${RESET} \$(load_indicator) \$(status_indicator \$?)\n''${BOLD}''${CONGO_BLUE}congo''${RESET}''${BOLD}❯''${RESET} "
    PS2="''${CONGO_YELLOW} > ''${RESET}"
    PS3="''${CONGO_RED} -> ''${RESET}"
    PS4="''${CONGO_BLUE} #-> ''${RESET}"

    # Enhanced history navigation (up/down arrows)
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
    bind '"\eOA": history-search-backward'
    bind '"\eOB": history-search-forward'

    # Tab completion settings
    set show-all-if-ambiguous on
    set completion-ignore-case on
    set completion-map-case on
    set show-all-if-unmodified on
    set menu-complete-display-prefix on

    # Enhanced history configuration
    shopt -s histappend
    shopt -s cmdhist
    shopt -s histverify
    export HISTCONTROL=ignoredups:erasedups:ignorespace
    export HISTSIZE=10000
    export HISTFILESIZE=20000
    export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
  '';
}