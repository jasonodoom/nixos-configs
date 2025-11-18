{ config, pkgs, lib, ... }:

{
  # Enable nix-darwin's built-in Homebrew management
  homebrew = {
    enable = true;

    # Auto-update Homebrew and upgrade packages on activation
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";  # Uninstall packages not listed below
    };

    # Taps (third-party repositories)
    taps = [
      "homebrew/cask-versions"
      "homebrew/cask-fonts"
    ];

    # CLI tools via Homebrew (prefer nixpkgs when available)
    brews = [
      "mas"  # Mac App Store CLI - required for masApps management
    ];

    # GUI applications via Homebrew Cask
    # These are managed declaratively - removed apps will be uninstalled on rebuild
    casks = [
      # Browsers
      "firefox"

      # Communication
      "discord"
      "slack"
      "signal"
      "telegram"
      "element"
      "zoom"

      # Development
      "iterm2"
      "github"
      "rancher-desktop"
      "virtualbox"

      # Media & Design
      "vlc"
      "obs"
      "audacity"
      "gimp"

      # Productivity
      "obsidian"
      "notion"
      "alfred"
      "raycast"

      # Utilities
      "little-snitch"
      "micro-snitch"
      "keka"
      "stats"
      "tailscale"
      "transmission"
      "wireshark"

      # Terminal
      "ghostty"

      # AI/ML
      "ollama"
      "rewind"

      # Misc
      "mqtt-explorer"
    ];

    # Then add apps here in format: "App Name" = app_id;
    # Example: "Xcode" = 497799835;
    masApps = {
      # Run 'mas list' after rebuild to see your installed apps and their IDs
    };
  };

  # Note: Homebrew is installed to /opt/homebrew on Apple Silicon
  # The following environment variables are automatically set by nix-darwin:
  # - HOMEBREW_PREFIX=/opt/homebrew
  # - PATH includes /opt/homebrew/bin
}
