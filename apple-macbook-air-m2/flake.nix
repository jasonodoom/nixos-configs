{
  description = "nix-darwin configuration for Apple MacBook Air M2 (theophany)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # Import modules
      imports = [
        ./modules/ssh.nix
        ./modules/gpg.nix
        ./modules/zsh/zsh.nix
        ./modules/screen.nix
        ./modules/tmux.nix
        ./modules/keys.nix
        # ./modules/determinate-nix-update.nix  # Disabled: determinate-nixd not available
      ];

      # System packages
      environment.systemPackages = with pkgs; [
        vim
        awscli2
        bash-completion
        coreutils-full
        claude-code
        direnv
        nix-direnv
        ripgrep
        flyctl
        nmap
        tshark
        tree
        wget
        neofetch
        krb5
        p11-kit
        openssh
        gnupg
        pinentry_mac
        yubikey-personalization
        yubikey-manager
        pre-commit
        git-interactive-rebase-tool
        mob
        gh
        shfmt
        shellcheck
        tmux
        nixfmt-rfc-style
        wrangler
        nodejs_20
        ncdu
        iftop
        lazydocker
        terraform
        packer
        ansible
        ansible-lint
        pass
        go
        codex
      ];

      # Enable Touch ID for sudo
      security.pam.services.sudo_local.touchIdAuth = true;

      # Set primary user for system defaults
      system.primaryUser = "jason";

      # Match existing nixbld group GID from old nix-darwin installation
      ids.gids.nixbld = 30000;

      # macOS system defaults
      system.defaults = {
        dock = {
          autohide = false;
          orientation = "left";
          show-recents = false;
          mru-spaces = false;
        };

        finder = {
          AppleShowAllExtensions = true;
          ShowPathbar = false;
          FXPreferredViewStyle = "Nlsv"; # List view
          FXEnableExtensionChangeWarning = false;
        };

        NSGlobalDomain = {
          AppleShowAllExtensions = true;
          InitialKeyRepeat = 15;
          KeyRepeat = 2;
          "com.apple.mouse.tapBehavior" = 1;
          "com.apple.trackpad.enableSecondaryClick" = true;
        };

        screencapture.location = "~/Downloads";
      };

      # Nix configuration
      nix = {
        package = pkgs.nix;
        settings = {
          experimental-features = "nix-command flakes";
          trusted-users = [ "root" "jason" ];

          # Binary caches
          substituters = [
            "https://cache.garnix.io"
            "https://odoom-nixos-configs.cachix.org"
            "https://cache.nixos.org/"
          ];
          trusted-public-keys = [
            "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
            "odoom-nixos-configs.cachix.org-1:ySk5iYiHKvbuE1FezCjusvvFR98rkXDLMM6bS8SH3SU="
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          ];

          # Remote builds
          builders-use-substitutes = true;
        };

        # Configure remote builder to perdurabo
        buildMachines = [{
          hostName = "jason@perdurabo";
          system = "x86_64-linux";
          maxJobs = 8;
          speedFactor = 1;
          supportedFeatures = [ "big-parallel" "nixos-test" ];
          mandatoryFeatures = [ ];
        }];
        distributedBuilds = true;
      };

      # Programs
      programs.zsh.enable = true;

      # Set Git commit hash for darwin-version
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility
      system.stateVersion = 5;

      # Host platform
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # Overlays
      nixpkgs.overlays = [
        (import ./overlays)
        # Skip fish tests that fail on macOS ARM64 due to missing pexpect module
        # https://github.com/NixOS/nixpkgs/issues/461406
        (final: prev: {
          fish = prev.fish.overrideAttrs (oldAttrs: {
            doCheck = false;
          });
        })
      ];
    };
  in
  {
    # darwin-rebuild build --flake .#theophany
    darwinConfigurations."theophany" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    # Expose the package set for convenience
    darwinPackages = self.darwinConfigurations."theophany".pkgs;
  };
}
