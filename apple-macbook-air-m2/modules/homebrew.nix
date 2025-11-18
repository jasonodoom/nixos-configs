{ config, pkgs, lib, ... }:

{
  # Enable nix-darwin's built-in Homebrew management
  # Obviously, not using brew outside of nix-darwin, but this helps manage
  # GUI applications and Mac App Store apps declaratively.
  homebrew = {
    enable = true;

    # Auto-update Homebrew and upgrade packages on activation
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";  # Uninstall packages not listed below
    };

    # Taps (third-party repositories)
    taps = [ ];

    # CLI tools via Homebrew (prefer nixpkgs when available)
    brews = [
      "mas"  # Mac App Store CLI - required for masApps management
    ];

    # GUI applications via Homebrew Cask
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
      "virtualbox"

      # Media & Design
      "vlc"
      "obs"
      # "audacity"  # existing version conflicts with Homebrew. Commenting for now.
      # "gimp"      # existing version conflicts with Homebrew. Commenting for now.

      # Productivity
      "obsidian"
      "notion"
      "alfred"
      "raycast"

      # Utilities
      "little-snitch"
      "micro-snitch"
      "stats"
      "tailscale-app"
      "transmission"
      "wireshark-app"

      # Terminal
      "ghostty"

      # AI/ML
      "ollama-app"
      "rewind"
    ];

    # Mac App Store apps 
    # mas list output can be used to find app IDs
    masApps = {
      "GarageBand" = 682658836;
      "iMovie" = 408981434;
      "Keka" = 470158793;
      "Keynote" = 409183694;
      "Manico" = 724472954;
      "MQTT Explorer" = 1455214828;
      "Numbers" = 409203825;
      "OP-Z" = 1098190457;
      "Pages" = 409201541;
      "Scrobbles for Last.fm" = 1344679160;
      "Shazam" = 897118787;
      "WireGuard" = 1451685025;
      # "Xcode" = 497799835;
      "Yubico Authenticator" = 1497506650;
    };
  };

  # Homebrew is installed to /opt/homebrew  and the following environment variables are set by nix-darwin:
  # - HOMEBREW_PREFIX=/opt/homebrew
  # - PATH includes /opt/homebrew/bin
}
