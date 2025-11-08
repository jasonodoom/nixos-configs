{
  description = "NixOS configuration for Framework Desktop with Hyprland";

  # Garnix CI cache configuration
  nixConfig = {
    substituters = [
      "https://cache.nixos.org/"
      "https://cache.garnix.io"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    nixos-hardware.url = "github:NixOS/nixos-hardware/master";


    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, agenix, nixos-hardware, flake-utils, ... }@inputs:
  let
    mkSystem = system: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs system;
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
        };
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

        ./modules/applications.nix
        ./modules/audio.nix
        ./modules/bluetooth.nix
        ./modules/development.nix
        ./modules/firefox.nix
        ./modules/fonts.nix
        ./modules/gaming.nix
        ./modules/git.nix
        ./modules/graphics.nix
        ./modules/hyprland/hyprland.nix
        ./modules/hyprland/dunst.nix
        ./modules/hyprland/waybar.nix
        ./modules/hyprland/rofi.nix
        ./modules/networking.nix
        ./modules/security.nix
        ./modules/shell.nix
        ./modules/system.nix
        ./modules/themes.nix  # SDDM themes
        ./modules/unfree.nix
        ./modules/user-config.nix
        ./modules/virtualization.nix
        ./modules/vscode.nix
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
        inherit system;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };
      };
    in
    {
      # VM tests for Hyprland and SDDM
      checks = pkgs.lib.optionalAttrs (system == "x86_64-linux") {
        hyprland-sddm = import ./tests/hyprland-sddm.nix { inherit pkgs; };
      };

      # Development shells
      devShells = {
        # Go development environment
        go = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
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

        # Node.js/TypeScript development environment
        node = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs
            nodePackages.typescript
            nodePackages.typescript-language-server
            nodePackages.prettier
            nodePackages.eslint
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

        # Infrastructure/DevOps environment
        devops = pkgs.mkShell {
          buildInputs = with pkgs; [
            terraform
            terraform-ls
            ansible
            ansible-lint
            kubectl
            k9s
            kustomize
            docker-compose
            helm
            awscli2
            eksctl
          ];
          shellHook = ''
            echo "☁️ DevOps development environment loaded"
            echo "Terraform version: $(terraform --version)"
            echo "Available tools: terraform, ansible, ansible-lint, kubectl, k9s, kustomize, docker-compose, helm, awscli2, eksctl"
          '';
        };
      };
    }));
}