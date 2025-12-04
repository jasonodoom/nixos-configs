{
    description = "nix-darwin configuration for Apple MacBook Air M2 (theophany)";

    nixConfig = {
      substituters = [
        "https://cache.nixos.org/"
        "https://odoom-nixos-configs.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "odoom-nixos-configs.cachix.org-1:ySk5iYiHKvbuE1FezCjusvvFR98rkXDLMM6bS8SH3SU="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      nix-darwin = {
        url = "github:LnL7/nix-darwin";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      agenix = {
        url = "github:ryantm/agenix";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    };

    outputs = inputs@{ self, nix-darwin, nixpkgs, agenix, ... }:
    let
      overlays = [
        (import ./overlays { inherit inputs; })
      ];
      configuration = { pkgs, ... }: {
        # Import modules
        imports = [
          agenix.darwinModules.default
          # Network
          ./modules/network/network.nix
          # Security
          ./modules/security/pam.nix
          ./modules/security/ssh.nix
          ./modules/security/gpg.nix
          ./modules/security/keys.nix
          ./modules/security/secrets.nix
          # Shell
          ./modules/shell/zsh/zsh.nix
          ./modules/shell/screen.nix
          ./modules/shell/tmux.nix
          # Apps & System
          ./modules/git.nix
          ./modules/neovim.nix
          ./modules/ghostty.nix
          ./modules/determinate-nix-update.nix
          ./modules/homebrew.nix
          ./modules/dock.nix
          ./modules/firefox.nix
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
          vscode
          maccy
          rectangle
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
          htop
          lazydocker
          terraform
          packer
          ansible
          ansible-lint
          pass
          go
          agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
        ];

        # Set primary user for system defaults
        system.primaryUser = "jason";

        # Environment variables
        environment.variables = {
          HOMEBREW_NO_ANALYTICS = "1";
          EDITOR = "nvim";
        };

        # macOS system defaults
        system.defaults = {
          finder = {
            AppleShowAllExtensions = true;
            ShowPathbar = false;
            FXPreferredViewStyle = "Nlsv";
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

        # Configure Nix via /etc/nix/nix.custom.conf (included by Determinate Nix)
        environment.etc."nix/nix.custom.conf".text = ''
          # Custom configuration
          trusted-users = root jason
          cores = 0  # Allow individual builds to use all 8 cores
          max-jobs = auto
          substituters = https://cache.nixos.org/ https://odoom-nixos-configs.cachix.org https://nix-community.cachix.org
          trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= odoom-nixos-configs.cachix.org-1:ySk5iYiHKvbuE1FezCjusvvFR98rkXDLMM6bS8SH3SU= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
          builders-use-substitutes = true
          builders = ssh://jason@perdurabo x86_64-linux - 8 1 big-parallel,nixos-test
        '';

        # Disable nix-darwin's Nix management (using Determinate Nix instead)
        nix.enable = false;

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
        nixpkgs.overlays = overlays;
      };
    in
    {
      # darwin-rebuild build --flake .#theophany
      darwinConfigurations."theophany" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };

      # Expose the package set for convenience
      darwinPackages = self.darwinConfigurations."theophany".pkgs;

      # Flake checks - validates configuration builds successfully
      checks.aarch64-darwin = {
        darwin-config = self.darwinConfigurations."theophany".system;
      };
    };
  }
