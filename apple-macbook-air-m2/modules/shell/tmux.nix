# Tmux Configuration - Session Restoration and Screen-like Keybindings
{ config, pkgs, lib, ... }:

{
  # Tmux for persistent sessions with screen-compatible keybindings
  programs.tmux = {
    enable = true;

    extraConfig = ''
      # =============================================================================
      # Basic settings
      # =============================================================================
      set -g mode-keys vi
      set -g clock-mode-style 24

      # =============================================================================
      # Session restoration
      # =============================================================================
      # No @resurrect-* / @continuum-* settings here on purpose. nix-darwin's
      # programs.tmux has no plugins option, so tpm never loads and those
      # settings are inert user options that read like a working safety net.
      # Restoration on this host is agent-sessions-snapshot/-restore instead.

      # =============================================================================
      # Screen-compatible keybindings (from your .screenrc)
      # =============================================================================
      # Note: In tmux, Ctrl+A is the default prefix, but we can bind direct keys

      # Your screen bindings: ^L windowlist, ^N new screen
      bind-key -n C-l choose-tree -Zw -F "#{window_index}: #{=60:window_name}#{window_flags}"
      bind-key -n C-n new-window        # Ctrl+N creates new window (like screen)
      bind-key -n C-S-l send-keys C-l   # Ctrl+Shift+L still clears the shell

      set -s extended-keys on
      set -as terminal-features "*:extkeys"

      # Additional screen-like navigation
      bind-key C-a last-window          # Ctrl+A Ctrl+A switches to last window
      bind-key Space next-window        # Space goes to next window
      bind-key BSpace previous-window   # Backspace goes to previous window

      # =============================================================================
      # Enhanced configuration
      # =============================================================================

      # Better mouse support
      set -g mouse on

      # Let OSC escape sequences (iTerm2/Ghostty tab color, title) from
      # nested processes pass through tmux to the outer terminal.
      set -g allow-passthrough on

      # Clipboard. The NixOS hosts get this from the yank plugin; darwin
      # had nothing wired, so copies landed in tmux's buffer and never
      # reached the system clipboard. Pipe through pbcopy for vi-mode and
      # mouse selections, and let OSC 52 work for programs inside tmux.
      set -g set-clipboard on
      set -as terminal-features "xterm-ghostty:clipboard"
      bind -T copy-mode-vi y send -X copy-pipe-and-cancel /usr/bin/pbcopy
      bind -T copy-mode-vi Enter send -X copy-pipe-and-cancel /usr/bin/pbcopy
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel /usr/bin/pbcopy

      # 256 color support (like your screen-256color)
      set -g default-terminal "screen-256color"
      set -ga terminal-overrides ",xterm-256color:Tc"

      set -g history-limit 100000

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

  # The server's socket lives under $TMUX_TMPDIR, which defaults to /tmp.
  # macOS prunes /tmp, and losing the socket does not kill the server: it
  # keeps running, unreachable, while every `tmux attach` reports "no server
  # running" until the session eventually dies with it. Keep the socket
  # somewhere nothing sweeps.
  #
  # This has to be an environment variable, not a shell hook. bash, zsh, the
  # launchd snapshot job and anything non-interactive all have to resolve
  # the same socket; if one of them falls back to /tmp it does not fail
  # loudly, it starts a second server alongside the real one.
  environment.variables.TMUX_TMPDIR = "$HOME/.local/run";

  # The mkdir is load-bearing: tmux does not create $TMUX_TMPDIR, and if it
  # is missing tmux does not fail, it silently falls back to /tmp. Without
  # this the whole change quietly reverts to the behaviour that lost the
  # session. mkBefore so it runs ahead of the agent-sessions restore hint,
  # which probes `tmux has-session` during init.
  programs.bash.interactiveShellInit = lib.mkBefore ''
    [ -d "$TMUX_TMPDIR" ] || mkdir -p "$TMUX_TMPDIR"
  '';
  programs.zsh.interactiveShellInit = lib.mkBefore ''
    [ -d "$TMUX_TMPDIR" ] || mkdir -p "$TMUX_TMPDIR"
  '';

  # Ensure tmux is available system-wide
  environment.systemPackages = with pkgs; [
    tmux
  ];
}
