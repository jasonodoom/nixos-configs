# NixOS Configurations

[![Garnix CI](https://img.shields.io/badge/garnix-CI-blue)](https://garnix.io/jasonodoom/nixos-configs)
[![Built with Nix](https://img.shields.io/badge/Built_With-Nix-5277C3.svg?logo=nixos&labelColor=73C3D5)](https://nixos.org)

A collection of NixOS system configurations for different machines.

## Systems

### Framework Desktop Max+ 395

- **Location**: `./framework-desktop/`
- **Description**: Pure NixOS configuration with Hyprland, LUKS encryption and isolated development shells
- **Build**: `sudo nixos-rebuild switch --flake github:jasonodoom/nixos-configs/framework-desktop#perdurabo`