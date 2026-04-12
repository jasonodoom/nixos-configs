# Default overlay file
{ inputs, ... }:

final: prev: {
  # Import all overlays
  inherit (import ./claude-code.nix final prev) claude-code;

  # Use Tailscale from nixpkgs-unstable for latest version
  tailscale = (import inputs.nixpkgs-unstable { system = final.stdenv.hostPlatform.system; }).tailscale;

  # LLM agents from numtide/llm-agents.nix
  llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
}