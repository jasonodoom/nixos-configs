# Tmux Configuration - with Screen-like Keybindings
{ config, pkgs, ... }:

{
  # Tmux for persistent sessions with screen-compatible keybindings
  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    newSession = true;

    # Tmux plugins for session restoration
    plugins = with pkgs.tmuxPlugins; [
      resurrect          # Save/restore sessions
      continuum          # Auto-save sessions
      sensible           # Sensible defaults
      yank              # Copy to system clipboard
      pain-control      # Better pane management
    ];

    extraConfig = ''
      # =============================================================================
      # Session restoration settings (macOS-like persistence)
      # =============================================================================
      set -g @resurrect-save 'S'
      set -g @resurrect-restore 'R'
      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-strategy-vim 'session'
      set -g @resurrect-processes 'ssh vim nvim man less more tail top htop watch'

      # Auto-save sessions every 15 minutes
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '15'

      # =============================================================================
      # Screen-compatible keybindings (from your .screenrc)
      # =============================================================================
      # Note: In tmux, Ctrl+A is the default prefix, but we can bind direct keys

      # Your screen bindings: ^L windowlist, ^N new screen
      bind-key -n C-l choose-window      # Ctrl+L shows window list (like screen)
      bind-key -n C-n new-window        # Ctrl+N creates new window (like screen)

      # Additional screen-like navigation
      bind-key C-a last-window          # Ctrl+A Ctrl+A switches to last window
      bind-key Space next-window        # Space goes to next window
      bind-key BSpace previous-window   # Backspace goes to previous window

      # =============================================================================
      # Enhanced configuration
      # =============================================================================

      # Better mouse support
      set -g mouse on

      # 256 color support (like your screen-256color)
      set -g default-terminal "screen-256color"
      set -ga terminal-overrides ",xterm-256color:Tc"

      # Increase scrollback (you had 5000 in screen)
      set -g history-limit 10000

      # No startup message (like your screen config)
      set -g display-time 2000

      # =============================================================================
      # Status bar (inspired by your detailed screen caption)
      # =============================================================================

      # Status bar configuration
      set -g status on
      set -g status-interval 5
      set -g status-position bottom
      set -g status-justify left

      # Colors matching your screen theme
      set -g status-style 'bg=#1a1b26,fg=#c0caf5'

      # Left side: time|day|date|hostname (like your screen caption)
      set -g status-left-length 50
      set -g status-left '#[fg=#7aa2f7,bold]%H:%M#[default]|#[fg=#bb9af7]%a#[default]|#[fg=#9ece6a]%b %d#[default]|#[fg=#f7768e]#h#[default] '

      # Window list in center (like your screen window list)
      set -g window-status-format '#[fg=#565f89] #I#F #W '
      set -g window-status-current-format '#[fg=#1a1b26,bg=#7aa2f7,bold] #I#F #W #[default]'

      # Right side: session info and load
      set -g status-right-length 50
      set -g status-right '#[fg=#565f89]#{session_name} #[fg=#f7768e]#(uptime | cut -d"," -f 3-)'

      # =============================================================================
      # Window and pane management
      # =============================================================================

      # Better window splitting (more intuitive)
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Pane resizing
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Session management
      bind S choose-session
      bind N new-session

      # Quick reload config
      bind r source-file ~/.tmux.conf \; display-message "tmux.conf reloaded!"

      # =============================================================================
      # Auto-start with Ghostty (optional)
      # =============================================================================
      # This will be handled in the terminal keybindings, not here
    '';
  };

  # Ensure tmux is available system-wide
  environment.systemPackages = with pkgs; [
    tmux
  ];
}
