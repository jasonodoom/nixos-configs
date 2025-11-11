# Bash Colors and Prompt Configuration
{ config, pkgs, lib, ... }:

{
  programs.bash.promptInit = ''
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
            echo -e " \033[0;33m($branch*)\033[0m"
          else
            echo -e " \033[0;32m($branch)\033[0m"
          fi
        fi
      fi
    }

    # Status indicator that takes exit code as parameter
    status_indicator() {
      local exit_code=$1
      if [[ $exit_code -eq 0 ]]; then
        echo -e "\033[0;32m✓\033[0m"
      else
        echo -e "\033[0;31m✗\033[0m"
      fi
    }

    # Git background check functions
    git_bg_start() {
      if git rev-parse --git-dir >/dev/null 2>&1; then
        echo -n -e "\033[48;5;28m"
      fi
    }

    git_bg_end() {
      if git rev-parse --git-dir >/dev/null 2>&1; then
        echo -n -e "\033[0m"
      fi
    }

    # Main PS1 with git-aware background highlighting
    PS1="''${BOLD}''${GREEN}\u''${RESET}''${BOLD}@''${GREEN}\h''${RESET} \$(git_bg_start)''${BLUE}\w\$(parse_git_branch) \$(status_indicator \$?)\$(git_bg_end)\n''${BOLD}''${YELLOW}❯ λ ''${RESET}"
    PS2=" > "
    PS3=" -> "
    PS4=" #-> "

    # FZF integration for better history search
    if command -v fzf >/dev/null 2>&1; then
      # FZF function definitions
      __fzf_history() {
        local selected
        selected=$(HISTTIMEFORMAT= history | fzf --tac --no-sort --query="$READLINE_LINE" | sed 's/^ *[0-9]* *//')
        if [[ -n "$selected" ]]; then
          READLINE_LINE="$selected"
          READLINE_POINT=''${#READLINE_LINE}
        fi
      }

      __fzf_file_widget() {
        local selected
        selected=$(fzf --preview 'cat {}' --preview-window=right:60%:wrap)
        if [[ -n "$selected" ]]; then
          READLINE_LINE="''${READLINE_LINE:0:READLINE_POINT}$selected''${READLINE_LINE:READLINE_POINT}"
          READLINE_POINT=$((READLINE_POINT + ''${#selected}))
        fi
      }

      # Ctrl+R: fuzzy history search
      bind '"\C-r": "\C-x1"'
      bind -x '"\C-x1": __fzf_history'

      # Ctrl+T: fuzzy file finder
      bind '"\C-t": "\C-x2"'
      bind -x '"\C-x2": __fzf_file_widget'
    fi

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

    # Autosuggestion bindings
    # Ctrl+F: accept full suggestion
    bind '"\C-f": "\C-x4"'
    bind -x '"\C-x4": __auto_suggest'

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