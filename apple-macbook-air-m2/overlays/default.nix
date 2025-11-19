{ inputs, ... }:

final: prev: {
  inherit (import ./claude-code.nix final prev) claude-code;

  # Use Tailscale from GitHub flake
  tailscale = inputs.tailscale.packages.${final.stdenv.hostPlatform.system}.default;
}
