# Default overlay file
{ inputs, ... }:

final: prev: {
  # Import all overlays
  inherit (import ./claude-code.nix final prev) claude-code;
  inherit (import ./code-server.nix final prev) code-server;

  # Use Tailscale from GitHub flake
  tailscale = inputs.tailscale.packages.${final.stdenv.hostPlatform.system}.default;
}