{
    description = "nix-darwin configuration for Apple MacBook Air M2 (theophany)";

    nixConfig = {
      substituters = [
        "https://cache.nixos.org/"
        "https://vega-cache.dev"
        "https://odoom-nixos-configs.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "vega-cache-1:cPagS1g69NQGwlBCyTTeKav/NhlN8a7ixuj2uLOkHrQ="
        "odoom-nixos-configs.cachix.org-1:ySk5iYiHKvbuE1FezCjusvvFR98rkXDLMM6bS8SH3SU="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      # Pinned just for wrangler. 4.93.0 on current nixpkgs-unstable
      # fails to build on macos (EBADF in pnpm tsup). Will drop
      # when nixpkgs ships a working wrangler.
      nixpkgs-wrangler-pin.url = "github:NixOS/nixpkgs/8a1b0127302ea51e05bf4ea5a291743fac442406";
      nix-darwin = {
        url = "github:LnL7/nix-darwin";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      agenix = {
        url = "github:ryantm/agenix";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

      llm-agents = {
        url = "github:numtide/llm-agents.nix";
      };
    };

    outputs = inputs@{ self, nix-darwin, nixpkgs, agenix, determinate, ... }:
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
          ./modules/security/defaults.nix
          ./modules/security/travel-hardening.nix
          # Shell
          ./modules/shell/bash/bash.nix
          ./modules/shell/zsh/zsh.nix
          ./modules/shell/screen.nix
          ./modules/shell/tmux.nix
          # Apps & System
          ./modules/git.nix
          ./modules/neovim.nix
          ./modules/ghostty.nix
          ./modules/determinate-nix-update.nix
          ./modules/darwin-auto-update.nix
          ./modules/sync-ai-history.nix
          ./modules/homebrew.nix
          ./modules/container.nix
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
          llm-agents.antigravity-cli
          llm-agents.codex
          container
          maccy
          rectangle
          ripgrep
          flyctl
          nmap
          tshark
          tree
          wget
          fastfetch
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
          nixfmt
          nixpkgs-review
          wrangler
          nodejs_22
          bun
          rustc
          cargo
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
          python3Packages.huggingface-hub
          agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
          ragenix
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

        # Determinate Nix configuration via nix-darwin module
        determinateNix = {
          enable = true;
          customSettings = {
            trusted-users = ["root" "jason"];
            cores = 4;
            max-jobs = 4;
            max-silent-time = 1800; # kill a build that emits nothing for 30 min
            timeout = 6 * 60 * 60; # hard cap any single build at 6 h
            connect-timeout = 5; # fail fast on an unreachable substituter
            stalled-download-timeout = 300; # fail a download stalled 5 min
            substituters = "https://cache.nixos.org/ https://odoom-nixos-configs.cachix.org https://nix-community.cachix.org https://vega-cache.dev";
            trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= odoom-nixos-configs.cachix.org-1:ySk5iYiHKvbuE1FezCjusvvFR98rkXDLMM6bS8SH3SU= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= vega-cache-1:cPagS1g69NQGwlBCyTTeKav/NhlN8a7ixuj2uLOkHrQ=";
            builders-use-substitutes = true;
            # Fields (space-separated): uri system ssh-key max-jobs speed-factor
            # supported-features required-features base64-host-key. The 8th field
            # pins perdurabo's host key so the root nix-daemon can verify the
            # builder without an entry in root's known_hosts (it offloads as
            # root, not as the logged-in user).
            builders = "ssh://jason@perdurabo x86_64-linux - 8 1 big-parallel,nixos-test - c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUZYeVFvV1lzQWQ3OTZoV3M2UlJyOVJNbFRib2U0S0J4cWs2bVMrSWE4cUo=";
          };
        };

        # Programs
        programs.zsh.enable = true;

        # direnv with nix-direnv caching so `cd` into a repo reuses the
        # evaluated dev-shell instead of re-running nix every time.
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        # Silence the long "direnv: export +FOO +BAR ..." dump that fires
        # on every cd. Must be set at the env level so it's in scope before
        # the direnv hook runs.
        environment.variables.DIRENV_LOG_FORMAT = "";

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
        modules = [
          determinate.darwinModules.default
          configuration
        ];
      };

      # Expose the package set for convenience
      darwinPackages = self.darwinConfigurations."theophany".pkgs;

      # Flake checks - validates configuration builds successfully
      checks.aarch64-darwin = {
        darwin-config = self.darwinConfigurations."theophany".system;
      };
    };
  }
