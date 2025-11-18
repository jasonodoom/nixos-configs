{ config, pkgs, lib, ... }:

{
  # Note: Ghostty is currently marked as broken on macOS in nixpkgs
  # Install using official signed binaries from: https://ghostty.org
  # After installation, you can manage the config file via this module

  # Create user ghostty config directory and file via activation script
  system.activationScripts.ghostty-config.text = ''
    USER_HOME="/Users/${config.system.primaryUser}"

    mkdir -p "$USER_HOME/.config/ghostty"

    cat > "$USER_HOME/.config/ghostty/config" << 'EOF'
# Font configuration
font-family = Fira Code
font-size = 12
font-thicken = true

# Window configuration
window-padding-x = 8
window-padding-y = 8
window-decoration = true
window-width = 141
window-height = 34

# Transparency and visual effects
background-opacity = 0.9
unfocused-split-opacity = 0.75

# Cursor configuration
cursor-style = block

# Tokyo Night theme colors
background = 1a1b26
foreground = c0caf5
cursor-color = c0caf5
cursor-text = 1a1b26

# Selection colors
selection-foreground = c0caf5
selection-background = 33467c

# 16-color palette (Tokyo Night)
palette = 0=#15161e
palette = 1=#f7768e
palette = 2=#9ece6a
palette = 3=#e0af68
palette = 4=#7aa2f7
palette = 5=#bb9af7
palette = 6=#7dcfff
palette = 7=#a9b1d6
palette = 8=#414868
palette = 9=#f7768e
palette = 10=#9ece6a
palette = 11=#e0af68
palette = 12=#7aa2f7
palette = 13=#bb9af7
palette = 14=#7dcfff
palette = 15=#c0caf5

# Mouse and clipboard
mouse-hide-while-typing = true
clipboard-read = allow
clipboard-write = allow

# Shell integration
shell-integration = detect
shell-integration-features = cursor,sudo,title

# Scrollback
scrollback-limit = 2000
EOF

    chmod 644 "$USER_HOME/.config/ghostty/config"
    chown ${config.system.primaryUser}:staff "$USER_HOME/.config/ghostty/config"
  '';
}
