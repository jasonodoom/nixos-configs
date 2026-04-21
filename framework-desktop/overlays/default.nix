# Default overlay file
{ inputs, ... }:

final: prev: {
  # Import all overlays
  inherit (import ./claude-code.nix final prev) claude-code;

  # Use Tailscale from nixpkgs-unstable for latest version
  tailscale = (import inputs.nixpkgs-unstable { system = final.stdenv.hostPlatform.system; }).tailscale;

  # LLM agents from numtide/llm-agents.nix
  llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};

  # Promote individual agents to top-level pkgs attrs so the AI microvm
  # module can reference pkgs.codex / pkgs.gemini-cli uniformly alongside
  # pkgs.claude-code.
  codex = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.codex;
  gemini-cli = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.gemini-cli;
}