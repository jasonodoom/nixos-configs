{
  description = "NixOS configuration for Framework Desktop";

  nixConfig = {
    substituters = [
      "https://install.determinate.systems"
      "https://cache.nixos.org/"
      "https://vega-cache.dev"
      "https://cache.garnix.io"
    ];
    trusted-public-keys = [
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "vega-cache-1:cPagS1g69NQGwlBCyTTeKav/NhlN8a7ixuj2uLOkHrQ="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-utils.url = "github:numtide/flake-utils";

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, agenix, determinate, nixos-hardware, flake-utils, microvm, ... }@inputs:
  let
    # Single source of truth for the Node.js runtime used by host
    # tooling (devshells, microvm runners, etc.). Bump here when the
    # current LTS rolls over; modules consume it via specialArgs as
    # `nodejsPkg` and the devShell below reads the same attr, so only
    # this line moves on the next bump.
    nodejsAttr = "nodejs_24";
    nodejsPkgFor = system: (import nixpkgs-unstable { inherit system; }).${nodejsAttr};

    mkSystem = system: nixpkgs.lib.nixosSystem {
      system = system;
      specialArgs = {
        inherit inputs;
        system = system;
        pkgs-unstable = import nixpkgs-unstable {
          system = system;
        };
        nodejsPkg = nodejsPkgFor system;
      };
      modules = [
        ({ config, pkgs, ... }: {
          nixpkgs.overlays = [
            self.overlays.default
          ];
        })

        # Hardware configuration
        ./hardware-configuration.nix

        # Framework Desktop hardware modules
        nixos-hardware.nixosModules.framework-13-7040-amd

        # Agenix for secrets management
        agenix.nixosModules.default

        # MicroVM host support
        microvm.nixosModules.host

        # Determinate Nix for enterprise features
        determinate.nixosModules.default

        ./modules/applications.nix
        ./modules/audio.nix
        ./modules/bash/bash.nix
        ./modules/bluetooth.nix
        ./modules/development.nix
        ./modules/firefox.nix
        ./modules/fonts.nix
        ./modules/gaming.nix
        ./modules/ghostty.nix
        ./modules/git.nix
        ./modules/neovim.nix
        ./modules/ollama.nix
        ./modules/gnome.nix
        ./modules/kitty.nix
        ./modules/graphics.nix
        ./modules/hyprland/hyprland.nix
        ./modules/hyprland/dunst.nix
        ./modules/hyprland/waybar.nix
        ./modules/hyprland/rofi.nix
        ./modules/screen.nix
        ./modules/tmux.nix
        ./modules/shell.nix
        ./modules/system.nix
        ./modules/power.nix
        ./modules/network/networking.nix
        ./modules/network/tailscale.nix
        ./modules/security/security.nix
        ./modules/security/secrets.nix
        ./modules/security/ssh.nix
        ./modules/security/gpg.nix
        ./modules/security/luks.nix
        ./modules/themes.nix  # SDDM themes
        ./modules/unfree.nix
        ./modules/user-config.nix
        ./modules/virtualization.nix
        ./modules/vscode.nix
        ./modules/services/verify-commits.nix
        ./modules/services/forgejo.nix
        ./modules/services/forgejo-runner-vm.nix
        ./modules/ai-microvms.nix
        ./modules/bosun-browser-microvm.nix
        ./modules/bosun.nix
        ./modules/agentic-tmux.nix
      ];
    };
  in
  {
    # Overlays for custom packages
    overlays.default = import ./overlays/default.nix { inherit inputs; };

    # NixOS configurations
    nixosConfigurations = {
      # Framework Desktop configuration
      perdurabo = mkSystem "x86_64-linux";
    };
  } // (flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        system = system;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };
      };
      pkgs-unstable = import nixpkgs-unstable {
        system = system;
      };
    in
    {
      # VM tests - ordered from fastest to most comprehensive
      checks = pkgs.lib.optionalAttrs (system == "x86_64-linux") {
        # Fast: CLI access (console, SSH, Tailscale)
        cli-access = import ./tests/cli-access-test.nix { inherit pkgs; };

        # Real boot of perdurabo's userspace; catches service regressions
        boot = import ./tests/boot-test.nix { inherit pkgs; };

        # Fast: initrd LUKS + tailscale wiring assertions (no VM boot)
        initrd-unlock = import ./tests/initrd-unlock-test.nix {
          inherit pkgs;
          nixosSystem = self.nixosConfigurations.perdurabo;
        };

        # Fast: guard against secrets leaking into the nix store
        no-store-secrets = import ./tests/no-store-secrets-test.nix {
          inherit pkgs;
          nixosSystem = self.nixosConfigurations.perdurabo;
        };

        # Fast: eval-check the forgejo-runner microvm module shape
        forgejo-runner-vm = import ./tests/forgejo-runner-vm-test.nix {
          inherit pkgs;
          nixosSystem = self.nixosConfigurations.perdurabo;
        };

        # Fast: eval-check the AI agent microvms
        ai-agents = import ./tests/ai-agents-test.nix {
          inherit pkgs;
          nixosSystem = self.nixosConfigurations.perdurabo;
        };

        # Fast: Service-only testing (headless, lightweight)
        desktop-switching = import ./tests/desktop-switching-test.nix { inherit pkgs pkgs-unstable; };

        # Comprehensive: Full desktop integration testing with screenshots
        desktop-integration = import ./tests/desktop-integration.nix { inherit pkgs pkgs-unstable; };
      };

      # Development shells
      devShells = {
        # Go development environment
        go = pkgs.mkShell {
          buildInputs = with pkgs; [
            pkgs-unstable.go_1_26
            gopls          # Language server
            gofumpt        # Formatter
            golangci-lint  # Linter
            delve          # Debugger
          ];
          shellHook = ''
            echo "🐹 Go development environment loaded"
            echo "Go version: $(go version)"
            echo "Available tools: go, gopls, gofumpt, golangci-lint, dlv"
          '';
        };

        # Python development environment
        python = pkgs.mkShell {
          buildInputs = with pkgs; [
            python3
            pyright        # Language server
            black          # Formatter
            isort          # Import sorter
            pylint         # Linter
            python3Packages.pytest  # Testing
          ];
          shellHook = ''
            echo "🐍 Python development environment loaded"
            echo "Python version: $(python --version)"
            echo "Available tools: python3, pyright, black, isort, pylint, pytest"
          '';
        };

        # Node.js/TypeScript development environment. Pinned to the
        # `nodejsAttr` defined at the top of this flake so the devShell
        # and the microvm modules stay on the same major.
        node = pkgs.mkShell {
          buildInputs = [
            (nodejsPkgFor system)
            pkgs.typescript
            pkgs.typescript-language-server
            pkgs.prettier
            pkgs.eslint
          ];
          shellHook = ''
            echo "🟢 Node.js development environment loaded"
            echo "Node version: $(node --version)"
            echo "NPM version: $(npm --version)"
            echo "Available tools: node, npm, tsc, prettier, eslint"
          '';
        };

        # Rust development environment
        rust = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustc
            cargo
            rust-analyzer
            rustfmt
            clippy
          ];
          shellHook = ''
            echo "🦀 Rust development environment loaded"
            echo "Rust version: $(rustc --version)"
            echo "Cargo version: $(cargo --version)"
            echo "Available tools: rustc, cargo, rust-analyzer, rustfmt, clippy"
          '';
        };

        # Infrastructure/DevOps environment. Uses opentofu instead of
        # terraform because Hashicorp's BSL license marked terraform
        # unfree in nixpkgs, which trips Garnix's allowUnfree=false
        # evaluator. opentofu is the OSS Apache-2.0 fork and is a
        # drop-in CLI replacement.
        devops = pkgs.mkShell {
          buildInputs = with pkgs; [
            opentofu
            terraform-ls
            kubectl
            k9s
            kustomize
            docker-compose
            helm
            awscli2
            eksctl
            flyctl
          ] ++ (with pkgs-unstable; [
            ansible
            ansible-lint
          ]);
          shellHook = ''
            echo "☁️ DevOps development environment loaded"
            echo "OpenTofu version: $(tofu --version | head -1)"
            echo "Available tools: tofu, terraform-ls, ansible, kubectl, k9s, kustomize, docker-compose, helm, awscli2, eksctl"
          '';
        };
      };
    }));
}
