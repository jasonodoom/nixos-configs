# Default overlay file
{ inputs, ... }:

final: prev: {
  # Import all overlays
  inherit (import ./claude-code.nix final prev) claude-code;

  # Use Tailscale from GitHub flake
  tailscale = inputs.tailscale.packages.${final.system}.default;
}