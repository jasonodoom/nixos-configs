# Default overlay file
{ inputs, ... }:

final: prev: {
  # Import all overlays
  inherit (import ./claude-code.nix final prev) claude-code;
}