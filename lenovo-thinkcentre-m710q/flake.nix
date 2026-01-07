{
  description = "NixOS configuration for Congo server";

  # Cachix cache configuration
  nixConfig = {
    substituters = [
      "https://cache.nixos.org/"
      "https://odoom-nixos-configs.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "odoom-nixos-configs.cachix.org-1:ySk5iYiHKvbuE1FezCjusvvFR98rkXDLMM6bS8SH3SU="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tailscale = {
      url = "github:tailscale/tailscale/v1.92.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, agenix, tailscale, determinate, flake-utils, ... }@inputs:
  let
    mkSystem = system: nixpkgs.lib.nixosSystem {
      system = system;
      specialArgs = {
        inherit inputs;
        system = system;
        pkgs-unstable = import nixpkgs-unstable {
          system = system;
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

        # Agenix for secrets management
        agenix.nixosModules.default

        # Core system modules
        ./modules/system.nix
        ./modules/bash/bash.nix
        ./modules/screen.nix
        ./modules/tmux.nix

        # Network
        ./modules/network/networking.nix
        ./modules/network/tailscale.nix

        # Security
        ./modules/security/security.nix
        ./modules/security/secrets.nix
        ./modules/security/ssh.nix
        ./modules/security/luks.nix
        ./modules/security/fail2ban.nix

        # Services
        ./modules/services/logs.nix

        # Container services
        # ./modules/containers/openbao.nix
        # ./modules/containers/pihole.nix
        # ./modules/containers/homepage.nix
      ];
    };
  in
  {
    # Overlays for custom packages
    overlays.default = final: prev: {
      # Use Tailscale from GitHub flake since Unstable does not have latest
      tailscale = tailscale.packages.${final.stdenv.hostPlatform.system}.default;
    };

    # NixOS configurations
    nixosConfigurations = {
      # Congo server configuration
      congo = mkSystem "x86_64-linux";
    };

    # Checks for x86_64-linux
    checks.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      cli-access = import ./tests/cli-access-test.nix { inherit pkgs; };
    };
  };
}